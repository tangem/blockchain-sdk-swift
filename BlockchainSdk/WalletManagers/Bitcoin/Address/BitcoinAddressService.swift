//
//  BitcoinAddressService.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 06.12.2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import HDWalletKit
import BitcoinCore

@available(iOS 13.0, *)
public class BitcoinAddressService {
    let legacy: BitcoinLegacyAddressService
    let bech32: BitcoinBech32AddressService
    
    init(networkParams: INetwork) {
        legacy = BitcoinLegacyAddressService(networkParams: networkParams)
        bech32 = BitcoinBech32AddressService(networkParams: networkParams)
    }
}

// MARK: - AddressValidator

@available(iOS 13.0, *)
extension BitcoinAddressService: AddressValidator {
    public func validate(_ address: String) -> Bool {
        legacy.validate(address) || bech32.validate(address)
    }
}

// MARK: - AddressProvider

@available(iOS 13.0, *)
extension BitcoinAddressService: AddressProvider {
    public func makeAddress(for publicKey: Wallet.PublicKey, with addressType: AddressType) throws -> AddressPublicKeyPair {
        switch addressType {
        case .default:
            let bech32AddressString = try bech32.makeAddress(from: publicKey.blockchainKey)
            return AddressPublicKeyPair(value: bech32AddressString, publicKey: publicKey, type: addressType)
        case .legacy:
            let legacyAddressString = try legacy.makeAddress(from: publicKey.blockchainKey)
            return AddressPublicKeyPair(value: legacyAddressString, publicKey: publicKey, type: addressType)
        }
    }
}

// MARK: - MultisigAddressProvider

@available(iOS 13.0, *)
extension BitcoinAddressService: MultisigAddressProvider {
	public func makeAddresses(from walletPublicKey: Data, with pairPublicKey: Data) throws -> [Address] {
        guard let script = try create1Of2MultisigOutputScript(firstPublicKey: walletPublicKey, secondPublicKey: pairPublicKey) else {
            throw BlockchainSdkError.failedToCreateMultisigScript
        }

        let legacyAddressString = try legacy.makeMultisigAddress(from: script.data.sha256Ripemd160)
        let scriptAddress = BitcoinScriptAddress(script: script, value: legacyAddressString, type: .legacy)

        let bech32AddressString = try bech32.makeMultisigAddress(from: script.data.sha256())
        let bech32Address = BitcoinScriptAddress(script: script, value: bech32AddressString, type: .default)

        return [bech32Address, scriptAddress]
	}
}

// MARK: - MultipleAddressProvider

@available(iOS 13.0, *)
extension BitcoinAddressService: MultipleAddressProvider {
    public func makeAddresses(from walletPublicKey: Data) throws -> [Address] {
        let legacyAddressString = try legacy.makeAddress(from: walletPublicKey)
        let bech32AddressString = try bech32.makeAddress(from: walletPublicKey)

        return [
            PlainAddress(value: legacyAddressString, type: .legacy),
            PlainAddress(value: bech32AddressString, type: .default),
        ]
    }
}

// MARK: - Private

@available(iOS 13.0, *)
private extension BitcoinAddressService {
    func create1Of2MultisigOutputScript(firstPublicKey: Data, secondPublicKey: Data) throws -> HDWalletScript? {
        var pubKeys = try [firstPublicKey, secondPublicKey].map { (key: Data) throws -> HDWalletKit.PublicKey in
            let key = try Secp256k1Key(with: key)
            let compressed = try key.compress()
            let deCompressed = try key.decompress()
            return HDWalletKit.PublicKey(uncompressedPublicKey: deCompressed, compressedPublicKey: compressed, coin: .bitcoin)
        }
        pubKeys.sort(by: { $0.compressedPublicKey.lexicographicallyPrecedes($1.compressedPublicKey) })
        return ScriptFactory.Standard.buildMultiSig(publicKeys: pubKeys, signaturesRequired: 1)
    }
}
