//
//  TronAddressService.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 24.03.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

public struct TronAddressService {
    private let prefix: UInt8 = 0x41
    private let addressLength = 21
    
    public init() {}
    
    static func toByteForm(_ base58String: String) -> Data? {
        guard let bytes = base58String.base58CheckDecodedBytes else {
            return nil
        }
        
        return Data(bytes)
    }
    
    static func toHexForm(_ base58String: String, length: Int?) -> String? {
        guard let data = toByteForm(base58String) else {
            return nil
        }
        
        let hex = data.hex
        if let length = length {
            return String(repeating: "0", count: length - hex.count) + hex
        } else {
            return hex
        }
    }
}

// MARK: - AddressProvider

@available(iOS 13.0, *)
extension TronAddressService: AddressProvider {
    public func makeAddress(for publicKey: Wallet.PublicKey, with addressType: AddressType) throws -> PlainAddress {
        let decompressedPublicKey = try Secp256k1Key(with: publicKey.blockchainKey).decompress()

        let data = decompressedPublicKey.dropFirst()
        let hash = data.sha3(.keccak256)

        let addressData = [prefix] + hash.suffix(addressLength - 1)
        let address = addressData.base58CheckEncodedString

        return PlainAddress(value: address, publicKey: publicKey, type: addressType)
    }
}

// MARK: - AddressValidator

@available(iOS 13.0, *)
extension TronAddressService: AddressValidator {
    public func validate(_ address: String) -> Bool {
        guard let decoded = address.base58CheckDecodedBytes else {
            return false
        }

        return decoded.starts(with: [prefix]) && decoded.count == addressLength
    }
}
