//
//  AddressServiceManagerUtility.swift
//  BlockchainSdkTests
//
//  Created by skibinalexander on 28.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import XCTest
import CryptoKit
import TangemSdk
import WalletCore

@testable import BlockchainSdk

final class AddressServiceManagerUtility {
    
    func makeTrustWalletAddressService(
        publicKey: Data,
        for blockchain: BlockchainSdk.Blockchain
    ) throws -> String {
        if let coin = CoinType(blockchain) {
            return try TrustWalletAddressService(coin: coin, publicKeyType: .init(blockchain)).makeAddress(from: publicKey)
        } else {
            throw NSError()
        }
    }
    
    func makeLocalWalletAddressService(
        publicKey: Data,
        for blockchain: BlockchainSdk.Blockchain
    ) throws -> String {
        try blockchain.getAddressService().makeAddress(from: publicKey)
    }
    
}
