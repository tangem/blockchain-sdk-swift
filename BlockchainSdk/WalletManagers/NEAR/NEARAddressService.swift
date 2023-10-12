//
//  NEARAddressService.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 12.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct NEARAddressService: AddressService {
    func makeAddress(for publicKey: Wallet.PublicKey, with addressType: AddressType) throws -> PlainAddress {
        fatalError("\(#function) not implemented yet!")
    }

    func validate(_ address: String) -> Bool {
        fatalError("\(#function) not implemented yet!")
    }
}
