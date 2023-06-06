//
//  SolanaAddressService.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 11.01.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Solana_Swift

public struct SolanaAddressService {}

// MARK: - AddressProvider

@available(iOS 13.0, *)
extension SolanaAddressService: AddressProvider {
    public func makeAddress(for publicKey: Wallet.PublicKey, with addressType: AddressType) throws -> AddressPublicKeyPair {
        try publicKey.blockchainKey.validateAsEdKey()
        let address = Base58.encode(publicKey.blockchainKey.bytes)

        return AddressPublicKeyPair(value: address, publicKey: publicKey, type: addressType)
    }
}

// MARK: - AddressValidator

@available(iOS 13.0, *)
extension SolanaAddressService: AddressValidator {
    public func validate(_ address: String) -> Bool {
        let publicKey = PublicKey(string: address)
        return publicKey != nil
    }
}
