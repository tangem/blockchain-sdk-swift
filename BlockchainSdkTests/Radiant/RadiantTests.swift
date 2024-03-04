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
    private let blockchain = Blockchain.radiant(testnet: false)
    
    // MARK: - Impementation
    
    /// https://github.com/trustwallet/wallet-core/blob/master/tests/chains/Bitcoin/BitcoinAddressTests.cpp
    func testP2PKH_PrefixAddress() throws {
        let publicKey = Wallet.PublicKey(seedKey: Data(hexString: "039d645d2ce630c2a9a6dbe0cbd0a8fcb7b70241cb8a48424f25593290af2494b9"), derivationType: .none)
        let addressAdapter = BitcoinWalletCoreAddressAdapter(coin: .bitcoinCash)
        let adapterAddress = try addressAdapter.makeAddress(for: publicKey, by: .p2pkh)
        
        let legacyAddressService = BitcoinLegacyAddressService(networkParams: BitcoinCashNetworkParams())
        let legacyAddress = try legacyAddressService.makeAddress(from: publicKey.blockchainKey)

        XCTAssertEqual(adapterAddress.description, "12dNaXQtN5Asn2YFwT1cvciCrJa525fAe4")
        XCTAssertEqual(adapterAddress.description, legacyAddress.value)
    }
    
    func testP2SH_PrefixAddress() throws {
        let publicKey = Wallet.PublicKey(seedKey: Data(hexString: "039d645d2ce630c2a9a6dbe0cbd0a8fcb7b70241cb8a48424f25593290af2494b9"), derivationType: .none)
        let addressAdapter = BitcoinWalletCoreAddressAdapter(coin: .bitcoinCash)
        let adapterAddress = try addressAdapter.makeAddress(for: publicKey, by: .p2sh)
        
        let legacyAddressService = BitcoinLegacyAddressService(networkParams: BitcoinCashNetworkParams())
        let legacyAddress = try legacyAddressService.makeP2ScriptAddress(for: publicKey.blockchainKey)

        XCTAssertEqual(adapterAddress.description, "33KPW4uKuyVFsCEh4YgDMF58zprnb817jZ")
        XCTAssertEqual(adapterAddress.description, legacyAddress)
    }
}
