//
//  BlockchainSdkTests.swift
//  BlockchainSdkTests
//
//  Created by Alexander Osokin on 04.12.2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import XCTest
import BitcoinCore
import TangemSdk

@testable import BlockchainSdk

class BlockchainSdkTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
    func testBtcAddress() {
        let btcAddress = "1PMycacnJaSqwwJqjawXBErnLsZ7RkXUAs"
        let publicKey = Data(hex: "0250863ad64a87ae8a2fe83c1af1a8403cb53f53e486d8511dad8a04887e5b2352")
        XCTAssertEqual(try! BitcoinLegacyAddressService(networkParams: BitcoinNetwork.mainnet.networkParams).makeAddress(from: publicKey), btcAddress)
    }
    
    func testDucatusAddressValidation() {
        XCTAssertTrue(Blockchain.ducatus.validate(address: "LokyqymHydUE3ZC1hnZeZo6nuART3VcsSU"))
    }
    
    func testLTCAddressValidation() {
        XCTAssertTrue(Blockchain.litecoin.validate(address: "LMbRCidgQLz1kNA77gnUpLuiv2UL6Bc4Q2"))
    }
    
    func testEthChecksum() {
        let ethAddressService = EthereumAddressService()
        let chesksummed = ethAddressService.toChecksumAddress("0xfb6916095ca1df60bb79ce92ce3ea74c37c5d359")
        XCTAssertEqual(chesksummed, "0xfB6916095ca1df60bB79Ce92cE3Ea74c37c5d359")
        
        XCTAssertTrue(ethAddressService.validate("0xfb6916095ca1df60bb79ce92ce3ea74c37c5d359"))
        XCTAssertTrue(ethAddressService.validate("0xfB6916095ca1df60bB79Ce92cE3Ea74c37c5d359"))
        
        let testCases = ["0x52908400098527886E0F7030069857D2E4169EE7",
                         "0x8617E340B3D01FA5F11F306F4090FD50E238070D",
                         "0xde709f2102306220921060314715629080e2fb77",
                         "0x27b1fdb04752bbc536007a920d24acb045561c26",
                         "0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed",
                         "0xfB6916095ca1df60bB79Ce92cE3Ea74c37c5d359",
                         "0xdbF03B407c01E7cD3CBea99509d93f8DDDC8C6FB",
                         "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb"]
        
        _ = testCases.map {
            let checksummed = ethAddressService.toChecksumAddress($0)
            XCTAssertNotNil(checksummed)
            XCTAssertTrue(ethAddressService.validate($0))
            XCTAssertTrue(ethAddressService.validate(checksummed!))
        }

        XCTAssertFalse(ethAddressService.validate("0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9adb"))
    }
    
    func testRskChecksum() {
        let rskAddressService = RskAddressService()
        let chesksummed = try! rskAddressService.makeAddress(from: Data(hex:"04BAEC8CD3BA50FDFE1E8CF2B04B58E17041245341CD1F1C6B3A496B48956DB4C896A6848BCF8FCFC33B88341507DD25E5F4609386C68086C74CF472B86E5C3820"))
        
        XCTAssertEqual(chesksummed, "0xc63763572D45171E4C25cA0818B44e5DD7f5c15b")
        
        let correctAddress = "0xc63763572d45171e4c25ca0818b44e5dd7f5c15b"
        let correctAddressWithChecksum = "0xc63763572D45171E4C25cA0818B44e5DD7f5c15b"
        
        XCTAssertTrue(rskAddressService.validate(correctAddress))
        XCTAssertTrue(rskAddressService.validate(correctAddressWithChecksum))
    }
    
    func testTxValidation() {
        let vm: WalletManager = BitcoinWalletManager(wallet: Wallet(blockchain: .bitcoin(testnet: false),
                                                                    addresses: [PlainAddress(value: "adfjbajhfaldfh", type: .default)],
                                                                    publicKey: .init(seedKey: Data(), derivedKey: nil, derivationPath: nil)))
        
        vm.wallet.add(coinValue: 10)
        XCTAssertNoThrow(try vm.createTransaction(amount: Amount(with: vm.wallet.amounts[.coin]!, value: 3),
                                                  fee: Fee(Amount(with: vm.wallet.amounts[.coin]!, value: 3)),
                                                  destinationAddress: ""))
        
        assert(try vm.createTransaction(amount: Amount(with: vm.wallet.amounts[.coin]!, value: -1),
                                        fee: Fee(Amount(with: vm.wallet.amounts[.coin]!, value: 3)),
                                        destinationAddress: ""),
               throws: TransactionErrors(errors: [.invalidAmount]))
        
        
        
        assert(try vm.createTransaction(amount: Amount(with: vm.wallet.amounts[.coin]!, value: 1),
                                        fee: Fee(Amount(with: vm.wallet.amounts[.coin]!, value: -1)),
                                        destinationAddress: ""),
               throws: TransactionErrors(errors: [.invalidFee]))
        
        assert(try vm.createTransaction(amount: Amount(with: vm.wallet.amounts[.coin]!, value: 11),
                                        fee: Fee(Amount(with: vm.wallet.amounts[.coin]!, value: 1)),
                                        destinationAddress: ""),
               throws: TransactionErrors(errors: [.amountExceedsBalance, .totalExceedsBalance]))
        
        
        assert(try vm.createTransaction(amount: Amount(with: vm.wallet.amounts[.coin]!, value: 1),
                                        fee: Fee(Amount(with: vm.wallet.amounts[.coin]!, value: 11)),
                                        destinationAddress: ""),
               throws: TransactionErrors(errors: [.feeExceedsBalance, .totalExceedsBalance]))
        
        assert(try vm.createTransaction(amount: Amount(with: vm.wallet.amounts[.coin]!, value: 3),
                                        fee: Fee(Amount(with: vm.wallet.amounts[.coin]!, value: 8)),
                                        destinationAddress: ""),
               throws: TransactionErrors(errors: [.totalExceedsBalance]))
    }
    
    func testDerivationStyle() {
        let legacy: DerivationStyle = .legacy
        let new: DerivationStyle = .new

        let fantom: Blockchain = .fantom(testnet: false)
        XCTAssertEqual(fantom.derivationPath(for: legacy)!.rawPath, "m/44'/1007'/0'/0/0")
        XCTAssertEqual(fantom.derivationPath(for: new)!.rawPath, "m/44'/60'/0'/0/0")
       
        let eth: Blockchain = .ethereum(testnet: false)
        XCTAssertEqual(eth.derivationPath(for: legacy)!.rawPath, "m/44'/60'/0'/0/0")
        XCTAssertEqual(eth.derivationPath(for: new)!.rawPath, "m/44'/60'/0'/0/0")
        
        let ethTest: Blockchain = .ethereum(testnet: true)
        XCTAssertEqual(ethTest.derivationPath(for: legacy)!.rawPath, "m/44'/1'/0'/0/0")
        XCTAssertEqual(ethTest.derivationPath(for: new)!.rawPath, "m/44'/1'/0'/0/0")
        
        let xrp: Blockchain = .xrp(curve: .secp256k1)
        XCTAssertEqual(xrp.derivationPath(for: legacy)!.rawPath, "m/44'/144'/0'/0/0")
        XCTAssertEqual(xrp.derivationPath(for: new)!.rawPath, "m/44'/144'/0'/0/0")
    }
    
    func testCodingKey() {
        // Did you get a compilation error here? If so, add your new blockchain to the array below
        switch Blockchain.bitcoin(testnet: false) {
        case .bitcoin: break
        case .litecoin: break
        case .stellar: break
        case .ethereum: break
        case .ethereumClassic: break
        case .rsk: break
        case .bitcoinCash: break
        case .binance: break
        case .cardano: break
        case .xrp: break
        case .ducatus: break
        case .tezos: break
        case .dogecoin: break
        case .bsc: break
        case .polygon: break
        case .avalanche: break
        case .solana: break
        case .fantom: break
        case .polkadot: break
        case .kusama: break
        case .tron: break
        case .arbitrum: break
        case .dash: break
        case .gnosis: break
        case .optimism: break
        case .ethereumFair: break
        case .ethereumPoW: break
        case .saltPay: break
        case .ton: break
        case .kava: break
        case .kaspa: break
        case .ravencoin: break
        case .cosmos: break
        case .terraV1: break
        case .terraV2: break
        case .cronos: break
            // READ BELOW:
            //
            // Did you get a compilation error here? If so, add your new blockchain to the array below
        }
        
        let blockchains: [Blockchain] = [
            .ethereum(testnet: false),
            .ethereumClassic(testnet: false),
            .litecoin,
            .bitcoin(testnet: false),
            .bitcoinCash(testnet: false),
            .xrp(curve: .secp256k1),
            .rsk,
            .binance(testnet: false),
            .tezos(curve: .secp256k1),
            .stellar(testnet: false),
            .cardano(shelley: true),
            .ducatus,
            .dogecoin,
            .bsc(testnet: false),
            .polygon(testnet: false),
            .avalanche(testnet: false),
            .solana(testnet: false),
            .polkadot(testnet: false),
            .kusama,
            .fantom(testnet: false),
            .tron(testnet: false),
            .arbitrum(testnet: false),
            .dash(testnet: false),
            .gnosis,
            .optimism(testnet: false),
            .ethereumFair,
            .ethereumPoW(testnet: false),
            .saltPay,
            .ton(testnet: false),
            .kava(testnet: false),
            .kaspa,
            .ravencoin(testnet: false),
            .cosmos(testnet: false),
            .terraV1,
            .terraV2,
            .cronos,
        ]
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        for blockchain in blockchains {
            let recoveredFromCodable = try? decoder.decode(Blockchain.self, from: try encoder.encode(blockchain))
            XCTAssertTrue(recoveredFromCodable == blockchain, "\(blockchain.displayName) codingKey test failed")
        }
    }
    
}
