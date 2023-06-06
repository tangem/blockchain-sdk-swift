//
//  BitcoinCashAddressService.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 14.02.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import HDWalletKit
import TangemSdk
import BitcoinCore

@available(iOS 13.0, *)
public class BitcoinCashAddressService {
    private let legacyService: BitcoinLegacyAddressService
    private let bitcoinCashAddressService: DefaultBitcoinCashAddressService
    
    public init(networkParams: INetwork) {
        self.legacyService = .init(networkParams: networkParams)
        self.bitcoinCashAddressService = .init(networkParams: networkParams)
    }
}

// MARK: - AddressValidator

@available(iOS 13.0, *)
extension BitcoinCashAddressService: AddressValidator {
    public func validate(_ address: String) -> Bool {
        bitcoinCashAddressService.validate(address) || legacyService.validate(address)
    }
}

// MARK: - AddressProvider

@available(iOS 13.0, *)
extension BitcoinCashAddressService: AddressProvider {
    public func makeAddress(for publicKey: Wallet.PublicKey, with addressType: AddressType) throws -> AddressPublicKeyPair {
        switch addressType {
        case .default:
            let address = try bitcoinCashAddressService.makeAddress(from: publicKey.blockchainKey)
            return AddressPublicKeyPair(value: address, publicKey: publicKey, type: addressType)
        case .legacy:
            let compressedKey = try Secp256k1Key(with: publicKey.blockchainKey).compress()
            let address = try legacyService.makeAddress(from: compressedKey)
            return AddressPublicKeyPair(value: address, publicKey: publicKey, type: addressType)
        }
    }
}

@available(iOS 13.0, *)
public class DefaultBitcoinCashAddressService {
    private let addressPrefix: String
    
    public init(networkParams: INetwork) {
        addressPrefix = networkParams.bech32PrefixPattern
    }
    
    public func makeAddress(from walletPublicKey: Data) throws -> String {
        let compressedKey = try Secp256k1Key(with: walletPublicKey).compress()
        let prefix = Data([UInt8(0x00)]) //public key hash
        let payload = compressedKey.sha256Ripemd160
        let walletAddress = HDWalletKit.Bech32.encode(prefix + payload, prefix: addressPrefix)
        return walletAddress
    }
    
    public func validate(_ address: String) -> Bool {
        return (try? BitcoinCashAddress(address)) != nil
    }
}
