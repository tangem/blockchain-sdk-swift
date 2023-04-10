//
//  KeyAddressesCompareTests.swift
//  BlockchainSdkTests
//
//  Created by skibinalexander on 04.04.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import XCTest
import CryptoKit
import TangemSdk
import WalletCore

@testable import BlockchainSdk

/// Basic testplan for validation blockchain address from PrivateKey TrustWallet
class KeyAddressesCompareTests: XCTestCase {
    
    // MARK: - Properties
    
    let addressesUtility = AddressServiceManagerUtility()
    
    // MARK: - Implementation
    
    func testBitcoinAddress() {
        let blockchain = Blockchain.bitcoin(testnet: false)
        
        // From public key
        let any_address_test_address = "bc1qcj2vfjec3c3luf9fx9vddnglhh9gawmncmgxhz"
        let any_address_test_pubkey = "02753f5c275e1847ba4d2fd3df36ad00af2e165650b35fe3991e9c9c46f68b12bc"
        
        addressesUtility.validate(address: any_address_test_address, publicKey: Data(hex: any_address_test_pubkey), for: blockchain)
    }
    
    func testEthereumFromKeyAddress() {
        let blockchain = Blockchain.ethereum(testnet: false)
        
        let test_address = "0x6C1b86ABe251EC1b4bB3595283E178b0C0849e08"
        let test_private_key = PrivateKey(data: Data(hex: "9c3d42d0515f0406ed350ab2abf3eaf761f8907802469b64052ac17e2250ae13"))
        let test_public_key = test_private_key!.getPublicKeySecp256k1(compressed: false).data
        
        addressesUtility.validate(address: test_address, publicKey: test_public_key, for: blockchain)
    }
    
    func testLitecoinFromKeyAddress() {
        let blockchain = Blockchain.litecoin
        
        let test_address = "ltc1q2jy3qwat4tdrzaz0908ywun784tks7vn77ky9j"
        let test_private_key = PrivateKey(data: Data(hex: "9c3d42d0515f0406ed350ab2abf3eaf761f8907802469b64052ac17e2250ae13"))
        let test_public_key = test_private_key!.getPublicKeySecp256k1(compressed: true).data
        
        addressesUtility.validate(address: test_address, publicKey: test_public_key, for: blockchain)
    }
    
    func testStellarFromKeyAddress() {
        let blockchain = Blockchain.stellar(testnet: false)
        
        let test_address = "GAE2SZV4VLGBAPRYRFV2VY7YYLYGYIP5I7OU7BSP6DJT7GAZ35OKFDYI"
        let test_private_key = PrivateKey(data: Data(hex: "59a313f46ef1c23a9e4f71cea10fc0c56a2a6bb8a4b9ea3d5348823e5a478722"))
        let test_public_key = test_private_key!.getPublicKeyEd25519().data
        
        addressesUtility.validate(address: test_address, publicKey: test_public_key, for: blockchain)
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
    
    func testBinance() {
        let blockchain = Blockchain.binance(testnet: false)
        
        let test_private_key = PrivateKey(data: Data(hex: "9c3d42d0515f0406ed350ab2abf3eaf761f8907802469b64052ac17e2250ae13"))
        let test_public_key = test_private_key!.getPublicKeySecp256k1(compressed: true).data
        let test_address = "bnb12jy3qwat4tdrzaz0908ywun784tks7vnwud8cp"
        
        addressesUtility.validate(address: test_address, publicKey: test_public_key, for: blockchain)
    }
    
    func testBsc() {
        let blockchain = Blockchain.bsc(testnet: false)
        
        let test_private_key = PrivateKey(data: Data(hex: "9c3d42d0515f0406ed350ab2abf3eaf761f8907802469b64052ac17e2250ae13"))
        let test_public_key = test_private_key!.getPublicKeySecp256k1(compressed: false).data
        let test_address = "0x6C1b86ABe251EC1b4bB3595283E178b0C0849e08"
        
        addressesUtility.validate(address: test_address, publicKey: test_public_key, for: blockchain)
    }
    
    func testSolanaFromKeyAddress() {
        let blockchain = Blockchain.solana(testnet: false)
        
        let test_private_key = PrivateKey(data: Data(Base58.decodeNoCheck(string: "A7psj2GW7ZMdY4E5hJq14KMeYg7HFjULSsWSrTXZLvYr")!))
        let test_public_key = test_private_key!.getPublicKeyEd25519().data
        let test_address = "7v91N7iZ9mNicL8WfG6cgSCKyRXydQjLh6UYBWwm6y1Q"
        
        addressesUtility.validate(address: test_address, publicKey: test_public_key, for: blockchain)
    }
    
    func testPolkadotFromKeyAddress() {
        let blockchain = Blockchain.polkadot(testnet: false)
        
        let test_private_key = PrivateKey(data: Data(hexString: "0xd65ed4c1a742699b2e20c0c1f1fe780878b1b9f7d387f934fe0a7dc36f1f9008"))
        let test_public_key = test_private_key!.getPublicKeyEd25519().data
        let test_address = "12twBQPiG5yVSf3jQSBkTAKBKqCShQ5fm33KQhH3Hf6VDoKW"
        
        addressesUtility.validate(address: test_address, publicKey: test_public_key, for: blockchain)
    }
    
    func testTron() {
        let blockchain = Blockchain.tron(testnet: false)
        
        let test_private_key = PrivateKey(data: Data(hex: "9c3d42d0515f0406ed350ab2abf3eaf761f8907802469b64052ac17e2250ae13"))
        let test_public_key = test_private_key!.getPublicKeySecp256k1(compressed: false).data
        let test_address = "TKppxKZh7CKPTHjcUFja3AkPTxkfNaCX8i"
        
        addressesUtility.validate(address: test_address, publicKey: test_public_key, for: blockchain)
    }
    
    func testTezosFromKeyAddress() {
        let blockchain = Blockchain.tezos(curve: .ed25519)
        
        let test_private_key = PrivateKey(data: Data(hex: "b177a72743f54ed4bdf51f1b55527c31bcd68c6d2cb2436d76cadd0227c99ff0"))
        let test_public_key = test_private_key!.getPublicKeyEd25519().data
        let test_address = "tz1cG2jx3W4bZFeVGBjsTxUAG8tdpTXtE8PT"
        
        addressesUtility.validate(address: test_address, publicKey: test_public_key, for: blockchain)
    }
    
    func testBscFromKeyAddress() {
        let blockchain = Blockchain.bsc(testnet: false)
        
        let test_private_key = PrivateKey(data: Data(hexString: "727f677b390c151caf9c206fd77f77918f56904b5504243db9b21e51182c4c06"))
        let test_public_key = test_private_key!.getPublicKeySecp256k1(compressed: false).data
        let test_address = "0xf3d468DBb386aaD46E92FF222adDdf872C8CC064"
        
        addressesUtility.validate(address: test_address,publicKey: test_public_key, for: blockchain)
    }
    
    func testPolygonFromKeyAddress() {
        let blockchain = Blockchain.polygon(testnet: false)
        
        let test_private_key = PrivateKey(data: Data(hex: "9c3d42d0515f0406ed350ab2abf3eaf761f8907802469b64052ac17e2250ae13"))
        let test_public_key = test_private_key!.getPublicKeySecp256k1(compressed: false).data
        let test_address = "0x6C1b86ABe251EC1b4bB3595283E178b0C0849e08"
        
        addressesUtility.validate(address: test_address,publicKey: test_public_key, for: blockchain)
    }
    
    func testDashFromKeyAddress() {
        let blockchain = Blockchain.dash(testnet: false)
        
        let test_private_key = PrivateKey(data: Data(hex: "9c3d42d0515f0406ed350ab2abf3eaf761f8907802469b64052ac17e2250ae13"))
        let test_public_key = test_private_key!.getPublicKeySecp256k1(compressed: true).data
        let test_address = "XiPpnhYq2C4GcLpsKt3nn4fPVoZtoNP4sg"
        
        addressesUtility.validate(address: test_address,publicKey: test_public_key, for: blockchain)
    }
    
    func testDogecoinFromKeyAddress() {
        let blockchain = Blockchain.dogecoin
        
        let test_private_key = PrivateKey(data: Data(hex: "9c3d42d0515f0406ed350ab2abf3eaf761f8907802469b64052ac17e2250ae13"))
        let test_public_key = test_private_key!.getPublicKeySecp256k1(compressed: true).data
        let test_address = "DCr5VhqaMtjxzQQtCaj8UJ9CYbiW8bbymp"
        
        addressesUtility.validate(address: test_address,publicKey: test_public_key, for: blockchain)
    }
    
    func testBitcoinCashFromKeyAddress() {
        let blockchain = Blockchain.bitcoinCash(testnet: false)
        
        let test_private_key = PrivateKey(data: Data(hex: "9c3d42d0515f0406ed350ab2abf3eaf761f8907802469b64052ac17e2250ae13"))
        let test_public_key = test_private_key!.getPublicKeySecp256k1(compressed: true).data
        let test_address = "bitcoincash:qp2gjypm4w4d5vt5fu4uu3mj0c74w6rejvpakqylvs"
        
        addressesUtility.validate(address: test_address,publicKey: test_public_key, for: blockchain)
    }
    
    func testArbitrumFromKeyAddress() {
        let blockchain = Blockchain.arbitrum(testnet: false)
        
        let test_private_key = PrivateKey(data: Data(hex: "9c3d42d0515f0406ed350ab2abf3eaf761f8907802469b64052ac17e2250ae13"))
        let test_public_key = test_private_key!.getPublicKeySecp256k1(compressed: false).data
        let test_address = "0x6C1b86ABe251EC1b4bB3595283E178b0C0849e08"
        
        addressesUtility.validate(address: test_address,publicKey: test_public_key, for: blockchain)
    }
    
}
