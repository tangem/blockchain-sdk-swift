//
//  AddressProvider.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 30.05.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public protocol AddressProvider {
    func makeAddress(for publicKey: Wallet.PublicKey, with addressType: AddressType) throws -> AddressPublicKeyPair
}

extension AddressService {
    public func makeAddress(for publicKey: Wallet.PublicKey, with addressType: AddressType) throws -> AddressPublicKeyPair {
        let address = try makeAddress(from: publicKey.blockchainKey)
        
        return AddressPublicKeyPair(value: address, publicKey: publicKey, type: addressType)
    }
}
