//
//  BIP39CompareTests.swift
//  BlockchainSdkTests
//
//  Created by skibinalexander on 03.04.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import XCTest
import CryptoKit
import TangemSdk
import WalletCore

@testable import BlockchainSdk

class BIP39AddressesCompareTests: XCTestCase {
    
    // MARK: - Static Data
    
    let mnemonics = [
        "broom ramp luggage this language sketch door allow elbow wife moon impulse",
        "ripple scissors kick mammal hire column oak again sun offer wealth tomorrow wagon turn fatal",
        "history step cheap card humble screen raise seek robot slot coral roof spoil wreck caution",
        "diary shine country alpha bridge coast loan hungry hip media sell crucial swarm share gospel lake visa coin dizzy physical basket",
        "poet spider smile swift roof pilot subject save hand diet ice universe over brown inspire ugly wide economy symbol shove episode patient plug swamp",
        "letter advice cage absurd amount doctor acoustic avoid letter advice cage absurd amount doctor acoustic avoid letter advice cage absurd amount doctor acoustic bless",
        "inmate flip alley wear offer often piece magnet surge toddler submit right radio absent pear floor belt raven price stove replace reduce plate home",
        "tiny escape drive pupil flavor endless love walk gadget match filter luxury"
    ]
    
    let mnemonic = "tiny escape drive pupil flavor endless love walk gadget match filter luxury"
    
    lazy var utility: MnemonicServiceManagerUtility = {
        .init(mnemonic: mnemonic, passphrase: "").validate()
    }()
    
    // MARK: - Properties
    
    let addressesUtility = AddressServiceManagerUtility()
    
    // MARK: - Implementation
    
    func testValidateMnemonics() {
        mnemonics.forEach {
            MnemonicServiceManagerUtility(mnemonic: $0, passphrase: "").validate()
        }
    }
    
    func testBitcoin() {
        let blockchain = Blockchain.bitcoin(testnet: false)
        
        utility.validate(blockchain: blockchain) { privateKey, publicKey in
            addressesUtility.validate(
                address: "bc1qa3hn4whckf7gazxh5zd7m0xyrk90ncu4vnda8m",
                publicKey: publicKey.publicKey,
                for: blockchain
            )
        }
    }
    
    func testEthereum() {
        let blockchain = Blockchain.ethereum(testnet: false)
        
        utility.validate(blockchain: blockchain) { privateKey, publicKey in
            addressesUtility.validate(
                address: "0xd0EEe5dAe303c76548C2bc2D4fbE753fdb014D00",
                publicKey: try! Secp256k1Key(with: publicKey.publicKey).decompress(),
                for: blockchain
            )
        }
    }
    
    func testLitecoin() {
        let blockchain = Blockchain.litecoin
        
        utility.validate(blockchain: blockchain) { privateKey, publicKey in
            addressesUtility.validate(
                address: "ltc1qa3hn4whckf7gazxh5zd7m0xyrk90ncu4g0helt",
                publicKey: publicKey.publicKey,
                for: blockchain
            )
        }
    }
    
    func testStellar() {
        let blockchain = Blockchain.stellar(testnet: false)
        
        utility.validate(blockchain: blockchain) { privateKey, publicKey in
            addressesUtility.validate(
                address: "GCVMG2KBXHKN5NJ5NRFIZOW7BQS2KCPDTSB2OUJ4QXO7KOZXVNGVC7VB",
                publicKey: publicKey.publicKey,
                for: blockchain
            )
        }
    }
    
    func testXrp() {
        let blockchain = Blockchain.xrp(curve: .secp256k1)
        
        utility.validate(blockchain: blockchain) { privateKey, publicKey in
            addressesUtility.validate(
                address: "r4Z95dPnSWe6Xd4wkQDeGazDEUnqrKUt1m",
                publicKey: publicKey.publicKey,
                for: blockchain
            )
        }
    }
    
    func testTon() {
        let blockchain = Blockchain.ton(testnet: false)
        
        utility.validate(blockchain: blockchain) { privateKey, publicKey in
            addressesUtility.validate(
                address: "EQCH3Xammj2HL0RhRcp1ZYvQPsaSahf46BQbcegjypjlfM2n",
                publicKey: publicKey.publicKey,
                for: blockchain
            )
        }
    }
    
    func testBinance() {
        let blockchain = Blockchain.binance(testnet: false)
        
        utility.validate(blockchain: blockchain) { privateKey, publicKey in
            addressesUtility.validate(
                address: "bnb1a3hn4whckf7gazxh5zd7m0xyrk90ncu4cdv6zc",
                publicKey: publicKey.publicKey,
                for: blockchain
            )
        }
    }
    
    func testBsc() {
        let blockchain = Blockchain.bsc(testnet: false)
        
        utility.validate(blockchain: blockchain) { privateKey, publicKey in
            addressesUtility.validate(
                address: "0xd0EEe5dAe303c76548C2bc2D4fbE753fdb014D00",
                publicKey: try! Secp256k1Key(with: publicKey.publicKey).decompress(),
                for: blockchain
            )
        }
    }
    
    func testSolana() {
        let blockchain = Blockchain.solana(testnet: false)
        
        utility.validate(blockchain: blockchain) { privateKey, publicKey in
            addressesUtility.validate(
                address: "CVb8cVLcHWtdvvk1mZjoEuUkHK4Lo4veEEHGciVYKd28",
                publicKey: publicKey.publicKey,
                for: blockchain
            )
        }
    }
    
    func testPolkadot() {
        let blockchain = Blockchain.polkadot(testnet: false)
        
        utility.validate(blockchain: blockchain) { privateKey, publicKey in
            addressesUtility.validate(
                address: "14ruBzwtf56LCxw6KK1BkYviTxKogrRAHpcAq47kvBFdUfHo",
                publicKey: publicKey.publicKey,
                for: blockchain
            )
        }
    }
    
    func testTron() {
        let blockchain = Blockchain.tron(testnet: false)
        
        utility.validate(blockchain: blockchain) { privateKey, publicKey in
            addressesUtility.validate(
                address: "TV1wjsh8kvCrsRuEU8grgvCDgRwrs6Eac3",
                publicKey: try! Secp256k1Key(with: publicKey.publicKey).decompress(),
                for: blockchain
            )
        }
    }
    
    func testTezos() {
        let blockchain = Blockchain.tezos(curve: .ed25519)
        
        utility.validate(blockchain: blockchain) { privateKey, publicKey in
            addressesUtility.validate(
                address: "tz1gn9FiG81Tu4dpAxL69wrpcKWbuuu3HuMj",
                publicKey: publicKey.publicKey,
                for: blockchain
            )
        }
    }
    
    func testPolygon() {
        let blockchain = Blockchain.polygon(testnet: false)
        
        utility.validate(blockchain: blockchain) { privateKey, publicKey in
            addressesUtility.validate(
                address: "0xd0EEe5dAe303c76548C2bc2D4fbE753fdb014D00",
                publicKey: try! Secp256k1Key(with: publicKey.publicKey).decompress(),
                for: blockchain
            )
        }
    }
    
    func testDash() {
        let blockchain = Blockchain.dash(testnet: false)
        
        utility.validate(blockchain: blockchain) { privateKey, publicKey in
            addressesUtility.validate(
                address: "XxEzYt2yQDsHgZxkcHXs7dg15XfX3xRu5d",
                publicKey: publicKey.publicKey,
                for: blockchain
            )
        }
    }
    
    func testDogecoin() {
        let blockchain = Blockchain.dogecoin
        
        utility.validate(blockchain: blockchain) { privateKey, publicKey in
            addressesUtility.validate(
                address: "DShFFtKijvYz4dYmUzDCos9p8Kp8LiPwkX",
                publicKey: publicKey.publicKey,
                for: blockchain
            )
        }
    }
    
    func testBitcoinCash() {
        let blockchain = Blockchain.bitcoinCash(testnet: false)
        
        utility.validate(blockchain: blockchain) { privateKey, publicKey in
            addressesUtility.validate(
                address: "bitcoincash:qrkx7w46lze8er5g67sfhmducswc470rj5umyvauan",
                publicKey: publicKey.publicKey,
                for: blockchain
            )
        }
    }
    
    func testArbitrum() {
        let blockchain = Blockchain.arbitrum(testnet: false)
        
        utility.validate(blockchain: blockchain) { privateKey, publicKey in
            addressesUtility.validate(
                address: "0xd0EEe5dAe303c76548C2bc2D4fbE753fdb014D00",
                publicKey: try! Secp256k1Key(with: publicKey.publicKey).decompress(),
                for: blockchain
            )
        }
    }
    
}

