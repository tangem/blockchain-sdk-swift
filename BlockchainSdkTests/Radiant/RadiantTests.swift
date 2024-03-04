//
//  RadiantTests.swift
//  BlockchainSdkTests
//
//  Created by skibinalexander on 01.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import XCTest
import WalletCore

import BitcoinCore

@testable import BlockchainSdk

final class RadiantTests: XCTestCase {
    // MARK: - Impementation
    
    /// https://github.com/trustwallet/wallet-core/blob/master/tests/chains/Bitcoin/BitcoinAddressTests.cpp
    func testP2PKH_PrefixAddress() throws {
        let publicKey = PublicKey(data: Data(hexString: "039d645d2ce630c2a9a6dbe0cbd0a8fcb7b70241cb8a48424f25593290af2494b9"), type: .secp256k1)!
        
        let walletCoreAddress = BitcoinAddress(publicKey: publicKey, prefix: CoinType.bitcoin.p2pkhPrefix)!
        
        let legacyService = BitcoinLegacyAddressService(networkParams: BitcoinCashNetworkParams())
        let legacyAddress = try legacyService.makeAddress(from: publicKey.data)
        
        XCTAssertEqual(legacyAddress.value, walletCoreAddress.description)
        XCTAssertEqual(walletCoreAddress.description, "12dNaXQtN5Asn2YFwT1cvciCrJa525fAe4")
    }
    
    /// https://github.com/trustwallet/wallet-core/blob/master/tests/chains/Bitcoin/BitcoinAddressTests.cpp
    func testP2SH_PrefixAddress() throws {
        let publicKey = PublicKey(data: Data(hexString: "039d645d2ce630c2a9a6dbe0cbd0a8fcb7b70241cb8a48424f25593290af2494b9"), type: .secp256k1)!
        let walletCoreAddress = BitcoinAddress.compatibleAddress(publicKey: publicKey, prefix: CoinType.bitcoin.p2shPrefix)
        XCTAssertEqual(walletCoreAddress.description, "3PQ5BD39rDikf7YW6pJ9a9tbS3QhvwvzTG")
    }
}
