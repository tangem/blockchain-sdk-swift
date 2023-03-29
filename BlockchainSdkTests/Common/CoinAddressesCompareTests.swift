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
    let wallet = HDWallet(mnemonic: "broom ramp luggage this language sketch door allow elbow wife moon impulse", passphrase: "")!
    
}

// MARK: - Compare Addresses from address string

extension CoinAddressesCompareTests {
    
    func testEthereumAddress() {
        let blockchain = Blockchain.ethereum(testnet: false)
        
        // Positive
        addressesUtility.validateTRUE(address: "0xeDe8F58dADa22c3A49dB60D4f82BAD428ab65F89", for: blockchain)
        addressesUtility.validateTRUE(address: "0xfb6916095ca1df60bb79ce92ce3ea74c37c5d359", for: blockchain)
        addressesUtility.validateTRUE(address: "0xfB6916095ca1df60bB79Ce92cE3Ea74c37c5d359", for: blockchain)
        addressesUtility.validateTRUE(address: "0x52908400098527886E0F7030069857D2E4169EE7", for: blockchain)
        
        let testCases = [
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
        
        testCases.forEach {
            addressesUtility.validateTRUE(address: $0, for: blockchain)
        }
        
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
        addressesUtility.validateTRUE(address: "1PMycacnJaSqwwJqjawXBErnLsZ7RkXUAs", for: blockchain)
        addressesUtility.validateTRUE(address: "bc1qcj2vfjec3c3luf9fx9vddnglhh9gawmncmgxhz", for: blockchain)
        
        // Negative
        addressesUtility.validateFALSE(address: "bc1q2ddhp55sq2l4xnqhpdv9xazg02v9dr7uu8c2p2", for: blockchain)
        addressesUtility.validateFALSE(address: "MPmoY6RX3Y3HFjGEnFxyuLPCQdjvHwMEny", for: blockchain)
        addressesUtility.validateFALSE(address: "abc", for: blockchain)
        addressesUtility.validateFALSE(address: "0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed", for: blockchain)
        addressesUtility.validateFALSE(address: "175tWpb8K1S7NmH4Zx6rewF9WQrcZv245W", for: blockchain)
        
        // From public key
        let any_address_test_address = "bc1qcj2vfjec3c3luf9fx9vddnglhh9gawmncmgxhz"
        let any_address_test_pubkey = "02753f5c275e1847ba4d2fd3df36ad00af2e165650b35fe3991e9c9c46f68b12bc"
        
        addressesUtility.validate(address: any_address_test_address, publicKey: Data(hex: any_address_test_pubkey), for: blockchain)
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
    
    func testRippleAddress() {
        let blockchain = Blockchain.xrp(curve: .secp256k1)
        
        // Positive
        addressesUtility.validateTRUE(address: "rDpysuumkweqeC7XdNgYNtzL5GxbdsmrtF", for: blockchain)
        addressesUtility.validateTRUE(address: "XVfvixWZQKkcenFRYApCjpTUyJ4BePTe3jJv7beatUZvQYh", for: blockchain)
        addressesUtility.validateTRUE(address: "rJjXGYnKNcbTsnuwoaP9wfDebB8hDX8jdQ", for: blockchain)
        addressesUtility.validateTRUE(address: "r36yxStAh7qgTQNHTzjZvXybCTzUFhrfav", for: blockchain)
        addressesUtility.validateTRUE(address: "XVfvixWZQKkcenFRYApCjpTUyJ4BePMjMaPqnob9QVPiVJV", for: blockchain)
        addressesUtility.validateTRUE(address: "rfxdLwsZnoespnTDDb1Xhvbc8EFNdztaoq", for: blockchain)
        addressesUtility.validateTRUE(address: "rU893viamSnsfP3zjzM2KPxjqZjXSXK6VF", for: blockchain)
        
        // Negative
    }
    
}

// MARK: - Compare Addresses from public key data

extension CoinAddressesCompareTests {
    
    func testEthereumFromKeyAddress() {
        let blockchain = Blockchain.ethereum(testnet: false)
        
        let path = "m/44'/60'/0'/0/1"
        let test_private_key = wallet.getKey(coin: .ethereum, derivationPath: path)
        let test_public_key = test_private_key.getPublicKeySecp256k1(compressed: true)
        let test_address = "0x996891c410FB76C19DBA72C6f6cEFF2d9DD069b1"
        
        addressesUtility.validate(address: test_address, publicKey: test_public_key.data, for: blockchain)
    }
    
    func testBitcoinFromKeyAddress() {
        let blockchain = Blockchain.bitcoin(testnet: false)
        
        // From public key
        let test_address = "bc1qcj2vfjec3c3luf9fx9vddnglhh9gawmncmgxhz"
        let test_public_key = "02753f5c275e1847ba4d2fd3df36ad00af2e165650b35fe3991e9c9c46f68b12bc"
        
        addressesUtility.validate(address: test_address, publicKey: Data(hex: test_public_key), for: blockchain)
    }
    
    func testRippleFromKeyAddress() {
        let blockchain = Blockchain.xrp(curve: .secp256k1)
        
        let test_address = "r36yxStAh7qgTQNHTzjZvXybCTzUFhrfav"
        let test_private_key = PrivateKey(data: Data(hex: "9c3d42d0515f0406ed350ab2abf3eaf761f8907802469b64052ac17e2250ae13"))
        let test_public_key = test_private_key!.getPublicKeySecp256k1(compressed: true).data
        
        addressesUtility.validate(address: test_address, publicKey: test_public_key, for: blockchain)
        
    }
    
    func testTONFromKeyAddress() {
        let blockchain = Blockchain.ton(testnet: false)
        
        let test_private_key = PrivateKey(data: Data(hex: "63474e5fe9511f1526a50567ce142befc343e71a49b865ac3908f58667319cb8"))
        let test_public_key = test_private_key!.getPublicKeyEd25519().data
        let test_address = "EQBm--PFwDv1yCeS-QTJ-L8oiUpqo9IT1BwgVptlSq3ts90Q"
        
        addressesUtility.validate(address: test_address, publicKey: test_public_key, for: blockchain)
        
    }
    
}
