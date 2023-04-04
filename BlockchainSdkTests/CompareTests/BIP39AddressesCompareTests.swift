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
            addressesUtility.validate(privateKey: .init(data: privateKey.privateKey)!, for: blockchain)
            addressesUtility.validate(
                address: "bc1qa3hn4whckf7gazxh5zd7m0xyrk90ncu4vnda8m",
                publicKey: publicKey.publicKey,
                for: .bitcoin(testnet: false)
            )
        }
    }
    
    func testEthereum() {
        let blockchain = Blockchain.ethereum(testnet: false)
        
        utility.validate(blockchain: blockchain) { privateKey, publicKey in
            addressesUtility.validate(privateKey: .init(data: privateKey.privateKey)!, for: blockchain)
            
            print(publicKey.publicKey.hexString)
            
            addressesUtility.validate(
                address: "0xd0EEe5dAe303c76548C2bc2D4fbE753fdb014D00",
                publicKey: try! Secp256k1Key(with: publicKey.publicKey).decompress(),
                for: .ethereum(testnet: false)
            )
        }
    }
    
}

