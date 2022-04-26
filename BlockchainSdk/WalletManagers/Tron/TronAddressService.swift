//
//  TronAddressService.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 24.03.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

class TronAddressService: AddressService {
    private let prefix: UInt8 = 0x41
    private let addressLength = 21
    
    init() {
        
    }
    
    func makeAddress(from walletPublicKey: Data) throws -> String {
        try walletPublicKey.validateAsSecp256k1Key()
        
        let decompressedPublicKey = try Secp256k1Key(with: walletPublicKey).decompress()
        
        let data = decompressedPublicKey.dropFirst()
        let hash = data.sha3(.keccak256)
        
        let addressData = [prefix] + hash.suffix(addressLength - 1)
        
        return addressData.base58CheckEncodedString
    }
    
    func validate(_ address: String) -> Bool {
        guard let decoded = address.base58CheckDecodedBytes else {
            return false
        }

        return decoded.starts(with: [prefix]) && decoded.count == addressLength
    }
    
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
