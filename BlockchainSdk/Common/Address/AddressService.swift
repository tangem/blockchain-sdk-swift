//
//  AddressService.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 20.04.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public protocol AddressService: AddressProvider {
    func makeAddress(from walletPublicKey: Data) throws -> String
    func validate(_ address: String) -> Bool
}

extension AddressService {
    public func makeAddress(from walletPublicKey: Data) throws -> Address {
        let value = try makeAddress(from: walletPublicKey)
        let address = PlainAddress(value: value, type: .default)
        return address
    }
}
