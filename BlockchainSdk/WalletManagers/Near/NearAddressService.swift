//
//  NearAddressService.swift
//  BlockchainSdk
//
//  Created by Pavel Grechikhin on 05.06.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Solana_Swift

public class NearAddressService: AddressService {
    public func makeAddress(from walletPublicKey: Data) throws -> String {
        try walletPublicKey.validateAsEdKey()
        return Base58.encode(walletPublicKey.bytes)
    }
    
    public func validate(_ address: String) -> Bool {
        guard !address.isEmpty, address.utf8.count < 32 else { return false }
        return true
    }
}
