//
//  KaspaAddressService.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 07.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BitcoinCore

@available(iOS 13.0, *)
public class KaspaAddressService {
    private let isTestnet: Bool
    private let prefix: String
    private let version: KaspaAddressComponents.KaspaAddressType

    init(isTestnet: Bool) {
        self.isTestnet = isTestnet
        self.prefix = isTestnet ? "kaspatest" : "kaspa"
        self.version = isTestnet ? .P2PK_Schnorr : .P2PK_ECDSA
    }
    
    func parse(_ address: String) -> KaspaAddressComponents? {
        guard
            let (prefix, data) = CashAddrBech32.decode(address),
            !data.isEmpty,
            let firstByte = data.first,
            let type = KaspaAddressComponents.KaspaAddressType(rawValue: firstByte)
        else {
            return nil
        }

        return KaspaAddressComponents(
            prefix: prefix,
            type: type,
            hash: data.dropFirst()
        )
    }
}


// MARK: - AddressProvider

@available(iOS 13.0, *)
extension KaspaAddressService: AddressProvider {
    public func makeAddress(for publicKey: Wallet.PublicKey, with addressType: AddressType) throws -> Address {
        let compressedKey = try Secp256k1Key(with: publicKey.blockchainKey).compress()
        
        let payloadData = isTestnet
            ? compressedKey.dropFirst()
            : compressedKey
        
        let address = CashAddrBech32.encode(version.rawValue.data + payloadData, prefix: prefix)
        return PlainAddress(value: address, publicKey: publicKey, type: addressType)
    }
}

// MARK: - AddressValidator

@available(iOS 13.0, *)
extension KaspaAddressService: AddressValidator {
    public func validate(_ address: String) -> Bool {
        guard
            let components = parse(address),
            components.prefix == self.prefix
        else {
            return false
        }

        let validStartLetters = ["q", "p"]
        guard
            let firstAddressLetter = address.dropFirst(prefix.count + 1).first,
            validStartLetters.contains(String(firstAddressLetter))
        else {
            return false
        }

        return true
    }
}
