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

class CoinAddressesCompareTests: XCTestCase {
    
    let addressesUtility = AddressServiceManagerUtility()
    
}

// MARK: - Compare Addresses from address string

extension CoinAddressesCompareTests {
    
    func testEthereumAddress() {
        let blockchain = Blockchain.ethereum(testnet: false)
        
        // Positive
        let positiveTestCases = [
            "0xeDe8F58dADa22c3A49dB60D4f82BAD428ab65F89",
            "0xfb6916095ca1df60bb79ce92ce3ea74c37c5d359",
            "0xfB6916095ca1df60bB79Ce92cE3Ea74c37c5d359",
            "0x52908400098527886E0F7030069857D2E4169EE7",
            "0x52908400098527886E0F7030069857D2E4169EE7",
            "0x8617E340B3D01FA5F11F306F4090FD50E238070D",
            "0xde709f2102306220921060314715629080e2fb77",
            "0x27b1fdb04752bbc536007a920d24acb045561c26",
            "0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed",
            "0xfB6916095ca1df60bB79Ce92cE3Ea74c37c5d359",
            "0xdbF03B407c01E7cD3CBea99509d93f8DDDC8C6FB",
            "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb",
            "0x6ECa00c52AFC728CDbF42E817d712e175bb23C7d",
        ]
        
        positiveTestCases.forEach {
            addressesUtility.validateTRUE(address: $0, for: blockchain)
        }
        
        // Negative
        addressesUtility.validateFALSE(address: "ede8f58dada22a49db60d4f82bad428ab65f89", for: blockchain)
    }
    
    func testBitcoinAddress() {
        let blockchain = Blockchain.bitcoin(testnet: false)
        
        // Positive
        let positiveTestCases = [
            "bc1q2ddhp55sq2l4xnqhpdv0xazg02v9dr7uu8c2p2",
            "1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2",
            "1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2",
            "1AC4gh14wwZPULVPCdxUkgqbtPvC92PQPN",
            "1PMycacnJaSqwwJqjawXBErnLsZ7RkXUAs",
            "bc1qcj2vfjec3c3luf9fx9vddnglhh9gawmncmgxhz"
        ]
        
        positiveTestCases.forEach {
            addressesUtility.validateTRUE(address: $0, for: blockchain)
        }
        
        // Negative
        let negativeTestCases = [
            "bc1q2ddhp55sq2l4xnqhpdv9xazg02v9dr7uu8c2p2",
            "MPmoY6RX3Y3HFjGEnFxyuLPCQdjvHwMEny",
            "abc",
            "0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed",
            "175tWpb8K1S7NmH4Zx6rewF9WQrcZv245W"
        ]
        
        negativeTestCases.forEach {
            addressesUtility.validateFALSE(address: $0, for: blockchain)
        }
    }
    
    func testLitecoinAddress() {
        let blockchain = Blockchain.litecoin
        
        // Positive
        addressesUtility.validateTRUE(address: "ltc1q5wmm9vrz55war9c0rgw26tv9un5fxnn7slyjpy", for: blockchain)
        addressesUtility.validateTRUE(address: "MPmoY6RX3Y3HFjGEnFxyuLPCQdjvHwMEny", for: blockchain)
        addressesUtility.validateTRUE(address: "LMbRCidgQLz1kNA77gnUpLuiv2UL6Bc4Q2", for: blockchain)
        
        // Negative
        addressesUtility.validateFALSE(address: "1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2", for: blockchain)
    }
    
    func testBitcoinCashAddress() {
        let blockchain = Blockchain.bitcoinCash(testnet: false)
        
        // Positive
        addressesUtility.validateTRUE(address: "bitcoincash:qruxj7zq6yzpdx8dld0e9hfvt7u47zrw9gfr5hy0vh", for: blockchain)
        addressesUtility.validateTRUE(address: "bitcoincash:prm3srpqu4kmx00370m4wt5qr3cp7sekmcksezufmd", for: blockchain)
        addressesUtility.validateTRUE(address: "bitcoincash:prm3srpqu4kmx00370m4wt5qr3cp7sekmcksezufmd", for: blockchain)
        addressesUtility.validateTRUE(address: "1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2", for: blockchain)
    }
    
    func testBinanaceAddress() {
        let blockchain = Blockchain.binance(testnet: false)
        
        // Positive
        addressesUtility.validateTRUE(address: "bnb1c2zwqqucrqvvtyxfn78ajm8w2sgyjf5eex5gcc", for: blockchain)
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
    
    func testStellarAddress() {
        let blockchain = Blockchain.stellar(testnet: false)
        
        // Positive
        let positiveTestCases = [
            "GAB6EDWGWSRZUYUYCWXAFQFBHE5ZEJPDXCIMVZC3LH2C7IU35FTI2NOQ",
            "GAE2SZV4VLGBAPRYRFV2VY7YYLYGYIP5I7OU7BSP6DJT7GAZ35OKFDYI"
        ]
        
        positiveTestCases.forEach {
            addressesUtility.validateTRUE(address: $0, for: blockchain)
        }
    }
    
    func testRippleAddress() {
        let blockchain = Blockchain.xrp(curve: .secp256k1)
        
        // Positive
        let positiveTestCases = [
            "rDpysuumkweqeC7XdNgYNtzL5GxbdsmrtF",
            "XVfvixWZQKkcenFRYApCjpTUyJ4BePTe3jJv7beatUZvQYh",
            "XVfvixWZQKkcenFRYApCjpTUyJ4BePTe3jJv7beatUZvQYh",
            "rJjXGYnKNcbTsnuwoaP9wfDebB8hDX8jdQ",
            "r36yxStAh7qgTQNHTzjZvXybCTzUFhrfav",
            "XVfvixWZQKkcenFRYApCjpTUyJ4BePMjMaPqnob9QVPiVJV",
            "rfxdLwsZnoespnTDDb1Xhvbc8EFNdztaoq",
            "rU893viamSnsfP3zjzM2KPxjqZjXSXK6VF",
        ]
        
        positiveTestCases.forEach {
            addressesUtility.validateTRUE(address: $0, for: blockchain)
        }
    }
    
    func testSolanaAddress() {
        let blockchain = Blockchain.solana(testnet: false)

        // Positive
        let positiveTestCases = [
            "7v91N7iZ9mNicL8WfG6cgSCKyRXydQjLh6UYBWwm6y1Q",
            "EN2sCsJ1WDV8UFqsiTXHcUPUxQ4juE71eCknHYYMifkd"
        ]
        
        positiveTestCases.forEach {
            addressesUtility.validateTRUE(address: $0, for: blockchain)
        }
    }
    
    func testPolkadotAddress() {
        let blockchain = Blockchain.polkadot(testnet: false)
        
        // Positve
        let positiveTestCases = [
            "12twBQPiG5yVSf3jQSBkTAKBKqCShQ5fm33KQhH3Hf6VDoKW",
            "14PhJGbzPxhQbiq7k9uFjDQx3MNiYxnjFRSiVBvBBBfnkAoM"
        ]
        
        positiveTestCases.forEach {
            addressesUtility.validateTRUE(address: $0, for: blockchain)
        }
        
        // Negative
        let negativeTestCases = [
            "cosmos1l4f4max9w06gqrvsxf74hhyzuqhu2l3zyf0480",
            "3317oFJC9FvxU2fwrKVsvgnMGCDzTZ5nyf",
            "ELmaX1aPkyEF7TSmYbbyCjmSgrBpGHv9EtpwR2tk1kmpwvG"
        ]
        
        negativeTestCases.forEach {
            addressesUtility.validateFALSE(address: $0, for: blockchain)
        }
    }
    
    func testBscAddress() {
        let blockchain = Blockchain.bsc(testnet: false)
        
        // Positve
        addressesUtility.validateTRUE(address: "0xf3d468DBb386aaD46E92FF222adDdf872C8CC064", for: blockchain)
    }
    
}
