//
//  DerivationKeyAddressesCompareTests.swift
//  BlockchainSdkTests
//
//  Created by skibinalexander on 13.04.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import XCTest
import CryptoKit
import TangemSdk
import WalletCore

@testable import BlockchainSdk

/// Basic testplan for validation blockchain address from mnemonic at master key
class DerivationKeyAddressesCompareTests: XCTestCase {
    
    // MARK: - Static Data
    
    let mnemonic = "tiny escape drive pupil flavor endless love walk gadget match filter luxury"
    
    lazy var utility: MnemonicServiceManagerUtility = {
        .init(mnemonic: mnemonic, passphrase: "")
    }()
    
    // MARK: - Properties
    
    let addressesUtility = AddressServiceManagerUtility()
    
    // MARK: - Implementation
    
    func testBitcoin() {
        let blockchain = Blockchain.bitcoin(testnet: false)
        
        utility.validate(
            blockchain: blockchain,
            derivation: MnemonicServiceManagerUtility.CompareDerivation(
                local: blockchain.derivationPath()!.rawPath,
                reference: "m/84'/0'/0'/0/0"
            )
        ) { privateKey, publicKey in
            addressesUtility.validate(
                address: "bc1qnvhettk30ch9j0c64cldwthktmd66w9xhyytgq",
                publicKey: publicKey.data,
                for: blockchain
            )
        }
    }
    
    func testLitecoin() {
        let blockchain = Blockchain.litecoin
        
        utility.validate(
            blockchain: blockchain,
            derivation: MnemonicServiceManagerUtility.CompareDerivation(
                local: blockchain.derivationPath()!.rawPath,
                reference: "m/84'/2'/0'/0/0"
            )
        ) { privateKey, publicKey in
            addressesUtility.validate(
                address: "ltc1qw0lem6vgtpgq2xffsqdw22dd7epzfz6e39wld9",
                publicKey: publicKey.data,
                for: blockchain
            )
        }
    }
    
    func testStellar() {
        let blockchain = Blockchain.stellar(testnet: false)
        
        utility.validate(
            blockchain: blockchain,
            derivation: MnemonicServiceManagerUtility.CompareDerivation(
                local: blockchain.derivationPath()!.rawPath,
                reference: "m/44'/148'/0'"
            )
        ) { privateKey, publicKey in
            addressesUtility.validate(
                address: "GCFW7Y6DNIP3LEYMACPWWIZB3L5UIIE2R3ZSKU3HFYZZULTO7UZKYSKI",
                publicKey: publicKey.data,
                for: blockchain
            )
        }
    }
    
    func testEthereum() {
        let blockchain = Blockchain.ethereum(testnet: false)
        
        utility.validate(
            blockchain: blockchain,
            derivation: MnemonicServiceManagerUtility.CompareDerivation(
                local: blockchain.derivationPath()!.rawPath,
                reference: "m/44'/60'/0'/0/0"
            )
        ) { privateKey, publicKey in
            addressesUtility.validate(
                address: "0x5984781A30B49B5E9b835278b08ACf296DF6874d",
                publicKey: publicKey.data,
                for: blockchain
            )
        }
    }
    
    func testEthereumClassic() {
        let blockchain = Blockchain.ethereumClassic(testnet: false)
        
        utility.validate(
            blockchain: blockchain,
            derivation: MnemonicServiceManagerUtility.CompareDerivation(
                local: blockchain.derivationPath()!.rawPath,
                reference: "m/44'/60'/0'/0/0"
            )
        ) { privateKey, publicKey in
            addressesUtility.validate(
                address: "0x40fb949258c65edb4F97FB4F40695ec739F8B46F",
                publicKey: publicKey.data,
                for: blockchain
            )
        }
    }
    
    func testBitcoinCash() {
        let blockchain = Blockchain.bitcoinCash(testnet: false)
        
        utility.validate(
            blockchain: blockchain,
            derivation: MnemonicServiceManagerUtility.CompareDerivation(
                local: blockchain.derivationPath()!.rawPath,
                reference: "m/44'/60'/0'/0/0"
            )
        ) { privateKey, publicKey in
            addressesUtility.validate(
                address: "bitcoincash:qqml0kr5t7eer7qrsnzvxa0xazzwun8v9q44km8zsn",
                publicKey: publicKey.data,
                for: blockchain
            )
        }
    }
    
    func testBinance() {
        let blockchain = Blockchain.binance(testnet: false)
        
        utility.validate(
            blockchain: blockchain,
            derivation: MnemonicServiceManagerUtility.CompareDerivation(
                local: blockchain.derivationPath()!.rawPath,
                reference: "m/44'/714'/0'/0/0"
            )
        ) { privateKey, publicKey in
            addressesUtility.validate(
                address: "bnb1at6qa8typl6hkvtgrh6pn2ll33ypwhnn5mut87",
                publicKey: publicKey.data,
                for: blockchain
            )
        }
    }
    
    func testCardano() {
        let blockchain = Blockchain.cardano(shelley: true)
        
        utility.validate(
            blockchain: blockchain,
            derivation: MnemonicServiceManagerUtility.CompareDerivation(
                local: blockchain.derivationPath()!.rawPath,
                reference: "m/1852'/1815'/0'/0/0"
            )
        ) { privateKey, publicKey in
            addressesUtility.validate(
                address: "addr1q9vytxjnyyk0uerq3wdvwdp68qz0682l46yrxx7jgcvw2ddvxz484jgfalkufmagd4yr64h0cw8tmealwd8cht78ss4ssxcea7",
                publicKey: publicKey.data,
                for: blockchain
            )
        }
    }
    
    func testTon() {
        let blockchain = Blockchain.ton(testnet: false)
        
        utility.validate(
            blockchain: blockchain,
            derivation: MnemonicServiceManagerUtility.CompareDerivation(
                local: blockchain.derivationPath()!.rawPath,
                reference: "m/44'/607'/0'/0/0"
            )
        ) { privateKey, publicKey in
            addressesUtility.validate(
                address: "EQBFqL_6IC03p3LZ8PSCxLTOIkKwU0X9INBJhY55F-EU9gVT",
                publicKey: publicKey.data,
                for: blockchain
            )
        }
    }
    
    func testDogecoin() {
        let blockchain = Blockchain.dogecoin
        
        utility.validate(
            blockchain: blockchain,
            derivation: MnemonicServiceManagerUtility.CompareDerivation(
                local: blockchain.derivationPath()!.rawPath,
                reference: "m/44'/3'/0'/0/0"
            )
        ) { privateKey, publicKey in
            addressesUtility.validate(
                address: "DEgYuoZXK4NeTg2t6Nhe7935onC13x1hGE",
                publicKey: publicKey.data,
                for: blockchain
            )
        }
    }
    
    func testBsc() {
        let blockchain = Blockchain.bsc(testnet: false)
        
        utility.validate(
            blockchain: blockchain,
            derivation: MnemonicServiceManagerUtility.CompareDerivation(
                local: blockchain.derivationPath()!.rawPath,
                reference: "m/44'/60'/0'/0/0"
            )
        ) { privateKey, publicKey in
            addressesUtility.validate(
                address: "0x5984781A30B49B5E9b835278b08ACf296DF6874d",
                publicKey: publicKey.data,
                for: blockchain
            )
        }
    }
    
    func testDash() {
        let blockchain = Blockchain.dash(testnet: false)
        
        utility.validate(
            blockchain: blockchain,
            derivation: MnemonicServiceManagerUtility.CompareDerivation(
                local: blockchain.derivationPath()!.rawPath,
                reference: "m/44'/5'/0'/0/0"
            )
        ) { privateKey, publicKey in
            addressesUtility.validate(
                address: "XrJYTTgJt4jgEst2uqskiAzHdjY13YQCdh",
                publicKey: publicKey.data,
                for: blockchain
            )
        }
    }
    
    func testTron() {
        let blockchain = Blockchain.tron(testnet: false)
        
        utility.validate(
            blockchain: blockchain,
            derivation: MnemonicServiceManagerUtility.CompareDerivation(
                local: blockchain.derivationPath()!.rawPath,
                reference: "m/44'/195'/0'/0/0"
            )
        ) { privateKey, publicKey in
            addressesUtility.validate(
                address: "TQmXHQ839u7eZEwhEnshWmc8yHYkGYQmqy",
                publicKey: publicKey.data,
                for: blockchain
            )
        }
    }
    
    func testArbitrum() {
        let blockchain = Blockchain.arbitrum(testnet: false)
        
        utility.validate(
            blockchain: blockchain,
            derivation: MnemonicServiceManagerUtility.CompareDerivation(
                local: blockchain.derivationPath()!.rawPath,
                reference: "m/44'/60'/0'/0/0"
            )
        ) { privateKey, publicKey in
            addressesUtility.validate(
                address: "0x5984781A30B49B5E9b835278b08ACf296DF6874d",
                publicKey: publicKey.data,
                for: blockchain
            )
        }
    }
    
    func testSolana() {
        let blockchain = Blockchain.solana(testnet: false)
        
        utility.validate(
            blockchain: blockchain,
            derivation: MnemonicServiceManagerUtility.CompareDerivation(
                local: blockchain.derivationPath()!.rawPath,
                reference: "m/44'/501'/0'"
            )
        ) { privateKey, publicKey in
            addressesUtility.validate(
                address: "9HPwXfkjEH3UvV4vJeCMuyZDNGf8xTEqUrfutokiSD39",
                publicKey: publicKey.data,
                for: blockchain
            )
        }
    }
    
    func testPolkadot() {
        let blockchain = Blockchain.polkadot(testnet: false)
        
        utility.validate(
            blockchain: blockchain,
            derivation: MnemonicServiceManagerUtility.CompareDerivation(
                local: blockchain.derivationPath()!.rawPath,
                reference: "m/44'/354'/0'/0/0"
            )
        ) { privateKey, publicKey in
            addressesUtility.validate(
                address: "1bMPHVn5uPZvibghMxSz1o3H54V4JGbU2EyrbbCKyvXHgE5",
                publicKey: publicKey.data,
                for: blockchain
            )
        }
    }
    
    func testOptimism() {
        let blockchain = Blockchain.optimism(testnet: false)
        
        utility.validate(
            blockchain: blockchain,
            derivation: MnemonicServiceManagerUtility.CompareDerivation(
                local: blockchain.derivationPath()!.rawPath,
                reference: "m/44'/60'/0'/0/0"
            )
        ) { privateKey, publicKey in
            addressesUtility.validate(
                address: "0x5984781A30B49B5E9b835278b08ACf296DF6874d",
                publicKey: publicKey.data,
                for: blockchain
            )
        }
    }
    
    func testAvalanche() {
        let blockchain = Blockchain.avalanche(testnet: false)
        
        utility.validate(
            blockchain: blockchain,
            derivation: MnemonicServiceManagerUtility.CompareDerivation(
                local: blockchain.derivationPath()!.rawPath,
                reference: "m/44'/60'/0'/0/0"
            )
        ) { privateKey, publicKey in
            addressesUtility.validate(
                address: "0x5984781A30B49B5E9b835278b08ACf296DF6874d",
                publicKey: publicKey.data,
                for: blockchain
            )
        }
    }
    
    func testKava() {
        let blockchain = Blockchain.kava(testnet: false)
        
        utility.validate(
            blockchain: blockchain,
            derivation: MnemonicServiceManagerUtility.CompareDerivation(
                local: blockchain.derivationPath()!.rawPath,
                reference: "m/44'/60'/0'/0/0"
            )
        ) { privateKey, publicKey in
            addressesUtility.validate(
                address: "kava1nvjc0aqqmstvayhxsnslvgftkdfr0l7qe6nmr9",
                publicKey: publicKey.data,
                for: blockchain
            )
        }
    }
    
    func testXrp() {
        let blockchain = Blockchain.xrp(curve: .secp256k1)
        
        utility.validate(
            blockchain: blockchain,
            derivation: MnemonicServiceManagerUtility.CompareDerivation(
                local: blockchain.derivationPath()!.rawPath,
                reference: "m/44'/144'/0'/0/0"
            )
        ) { privateKey, publicKey in
            addressesUtility.validate(
                address: "rfcYjCaEDJX9ETHe4t3bxD7GkayhdaASfp",
                publicKey: publicKey.data,
                for: blockchain
            )
        }
    }
    
    func testTezos() {
        let blockchain = Blockchain.tezos(curve: .ed25519)
        
        utility.validate(
            blockchain: blockchain,
            derivation: MnemonicServiceManagerUtility.CompareDerivation(
                local: blockchain.derivationPath()!.rawPath,
                reference: "m/44'/1729'/0'/0/0"
            )
        ) { privateKey, publicKey in
            addressesUtility.validate(
                address: "tz1bpvevsxE1rGbqxTRHTaPqmKKhANzW61rr",
                publicKey: publicKey.data,
                for: blockchain
            )
        }
    }
    
    func testRavencoin() {
        let blockchain = Blockchain.ravencoin(testnet: false)
        
        utility.validate(
            blockchain: blockchain,
            derivation: MnemonicServiceManagerUtility.CompareDerivation(
                local: blockchain.derivationPath()!.rawPath,
                reference: "m/44'/175'/0'/0/0"
            )
        ) { privateKey, publicKey in
            addressesUtility.validate(
                address: "RPTqwXzy7LmMLbPWdDE4yP3QBThMJij3ZY",
                publicKey: publicKey.data,
                for: blockchain
            )
        }
    }
    
    func testFantom() {
        let blockchain = Blockchain.fantom(testnet: false)
        
        utility.validate(
            blockchain: blockchain,
            derivation: MnemonicServiceManagerUtility.CompareDerivation(
                local: blockchain.derivationPath()!.rawPath,
                reference: "m/44'/60'/0'/0/0"
            )
        ) { privateKey, publicKey in
            addressesUtility.validate(
                address: "0x5984781A30B49B5E9b835278b08ACf296DF6874d",
                publicKey: publicKey.data,
                for: blockchain
            )
        }
    }
    
}
