//
//  TronAddressService.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 24.03.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import WalletCore

class TronAddressService: AddressService {
    private let prefix: UInt8 = 0x41
    private let addressLength = 21
    
    init() {}
    
    func makeAddress(from walletPublicKey: Data) throws -> String {
        let decompressedPublicKey = try Secp256k1Key(with: walletPublicKey).decompress()
        
        guard let publicKey = PublicKey(data: decompressedPublicKey, type: .secp256k1Extended) else {
            throw BlockchainSdkError.wrongKey
        }
        
        let address = AnyAddress(publicKey: publicKey, coin: .tron)
        return address.description
    }
    
    func validate(_ address: String) -> Bool {
        let tronAddress = AnyAddress(string: address, coin: .tron)
        return tronAddress != nil
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
