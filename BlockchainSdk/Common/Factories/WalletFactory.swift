//
//  WalletFactory.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 30.05.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public struct WalletFactory {
    let addressProvider: AddressProvider
    
    func makeWallet(blockchain: Blockchain, publicKeys: [AddressType: Wallet.PublicKey]) throws -> Wallet {
        assert(publicKeys[.default] != nil, "PublicKeys have to contains default publicKey")
        
        let addresses: [AddressType: AddressPublicKeyPair] = try publicKeys.reduce(into: [:]) { result, args in
            let (addressType, publicKey) = args

            result[addressType] = try addressProvider.makeAddress(for: publicKey, with: addressType)
        }

        return Wallet(blockchain: blockchain, addresses: addresses)
    }
}
