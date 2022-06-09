//
//  NearAddressService.swift
//  BlockchainSdk
//
//  Created by Pavel Grechikhin on 05.06.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

public class NearAddressService: AddressService {
    public func makeAddress(from walletPublicKey: Data) throws -> String {
        try walletPublicKey.validateAsEdKey()
        let nearKey = NearPublicKey(from: walletPublicKey)
        return nearKey.address()
    }
    
    public func validate(_ address: String) -> Bool {
        guard !address.isEmpty, address.utf8.count >= 2, address.utf8.count <= 64 else { return false }
        return true
    }
}
