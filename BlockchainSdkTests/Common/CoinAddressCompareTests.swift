//
//  CoinAddressCompareTests.swift
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

class CoinAddressCompareTests: XCTestCase {
    
    let addressesUtility = AddressServiceManagerUtility()
    
    func testEthereumAddress() {
        let blockchain = Blockchain.ethereum(testnet: false)
        
        // Positive
        addressesUtility.validateTRUE(address: "0xeDe8F58dADa22c3A49dB60D4f82BAD428ab65F89", for: blockchain)
        
        // Negative
        addressesUtility.validateFALSE(address: "ede8f58dada22a49db60d4f82bad428ab65f89", for: blockchain)
    }
    
    func testBitcoinAddress() {
        let blockchain = Blockchain.bitcoin(testnet: false)
        
        // Positive
        addressesUtility.validateTRUE(address: "bc1q2ddhp55sq2l4xnqhpdv0xazg02v9dr7uu8c2p2", for: blockchain)
        addressesUtility.validateTRUE(address: "1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2", for: blockchain)
        addressesUtility.validateTRUE(address: "1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2", for: blockchain)
        addressesUtility.validateTRUE(address: "1AC4gh14wwZPULVPCdxUkgqbtPvC92PQPN", for: blockchain)
        
        // Negative
        addressesUtility.validateFALSE(address: "bc1q2ddhp55sq2l4xnqhpdv9xazg02v9dr7uu8c2p2", for: blockchain)
        addressesUtility.validateFALSE(address: "MPmoY6RX3Y3HFjGEnFxyuLPCQdjvHwMEny", for: blockchain)
        addressesUtility.validateFALSE(address: "abc", for: blockchain)
        addressesUtility.validateFALSE(address: "0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed", for: blockchain)
        addressesUtility.validateFALSE(address: "175tWpb8K1S7NmH4Zx6rewF9WQrcZv245W", for: blockchain)
    }
    
    func testLitecoinAddress() {
        let blockchain = Blockchain.litecoin
        
        // Positive
        addressesUtility.validateTRUE(address: "ltc1q5wmm9vrz55war9c0rgw26tv9un5fxnn7slyjpy", for: blockchain)
        addressesUtility.validateTRUE(address: "MPmoY6RX3Y3HFjGEnFxyuLPCQdjvHwMEny", for: blockchain)
        
        // Negative
        addressesUtility.validateFALSE(address: "1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2", for: blockchain)
    }
    
    func testBitcoinCashAddress() {
        let blockchain = Blockchain.bitcoinCash(testnet: false)
        
        // Positive
        addressesUtility.validateTRUE(address: "bitcoincash:qruxj7zq6yzpdx8dld0e9hfvt7u47zrw9gfr5hy0vh", for: blockchain)
        addressesUtility.validateTRUE(address: "1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2", for: blockchain)
    }
    
    func testTezosAddress() {
        let blockchain = Blockchain.tezos(curve: .ed25519)
        
        // Positive
        addressesUtility.validateTRUE(address: "tz1d1qQL3mYVuiH4JPFvuikEpFwaDm85oabM", for: blockchain)
        
        // Negative
        addressesUtility.validateFALSE(address: "tz1eZwq8b5cvE2bPKokatLkVMzkxz24z3AAAA", for: blockchain)
        addressesUtility.validateFALSE(address: "1tzeZwq8b5cvE2bPKokatLkVMzkxz24zAAAAA", for: blockchain)
    }
    
    func testTronAddress() {
        let blockchain = Blockchain.tron(testnet: false)
        
        // Positive
        addressesUtility.validateTRUE(address: "TJRyWwFs9wTFGZg3JbrVriFbNfCug5tDeC", for: blockchain)
        
        // Negative
        addressesUtility.validateFALSE(address: "abc", for: blockchain)
        addressesUtility.validateFALSE(address: "0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed", for: blockchain)
        addressesUtility.validateFALSE(address: "175tWpb8K1S7NmH4Zx6rewF9WQrcZv245W", for: blockchain)
    }
    
}
