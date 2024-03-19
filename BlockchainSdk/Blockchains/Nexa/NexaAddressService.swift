//
//  NexaAddressService.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 19.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

// TODO: Will change on the real
class NexaAddressService: AddressService {
    
    func makeAddress(for publicKey: Wallet.PublicKey, with addressType: AddressType) throws -> Address {
        return PlainAddress(value: "", publicKey: publicKey, type: addressType)
    }
    
    func validate(_ address: String) -> Bool {
        return false
    }
}
