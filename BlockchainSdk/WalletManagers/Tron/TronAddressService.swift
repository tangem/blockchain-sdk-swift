//
//  TronAddressService.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 24.03.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

class TronAddressService: AddressService {
    private let prefix: UInt8 = 0x41
    
    init() {

    }
    
    func makeAddress(from walletPublicKey: Data) throws -> String {
        try walletPublicKey.validateAsSecp256k1Key()

        let data = walletPublicKey.dropFirst()
        let hash = data.sha3(.keccak256)
        let addressData = [prefix] + hash.suffix(20)

        return addressData.base58CheckEncodedString
    }
    
    func validate(_ address: String) -> Bool {
        guard let decoded = address.base58CheckDecodedBytes else {
            return false
        }
        return decoded.starts(with: [prefix])
    }
}
