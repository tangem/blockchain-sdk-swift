//
//  BlockchainSdkTests.swift
//  BlockchainSdkTests
//
//  Created by Alexander Osokin on 04.12.2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import XCTest
import TangemSdk
import BitcoinCore
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

    func testBase58() {
        let ethalonString = "1NS17iag9jJgTHD1VXjvLCEnZuQ3rJDE9L"
        let testData = Data(hex: "00eb15231dfceb60925886b67d065299925915aeb172c06647")
        let encoded = String(base58: testData, alphabet: Base58String.btcAlphabet)
        XCTAssertEqual(ethalonString, encoded)
    }
    
    func testBtcAddress() {
        let btcAddress = "1PMycacnJaSqwwJqjawXBErnLsZ7RkXUAs"
        let publicKey = Data(hex: "0250863ad64a87ae8a2fe83c1af1a8403cb53f53e486d8511dad8a04887e5b2352")
        XCTAssertEqual(BitcoinLegacyAddressService(networkParams: BitcoinNetwork.mainnet.networkParams).makeAddress(from: publicKey), btcAddress)
    }
    
    func testDucatusAddressValidation() {
        XCTAssertTrue(Blockchain.ducatus.validate(address: "LokyqymHydUE3ZC1hnZeZo6nuART3VcsSU"))
    }
    
    func testLTCAddressValidation() {
        XCTAssertTrue(Blockchain.litecoin.validate(address: "LMbRCidgQLz1kNA77gnUpLuiv2UL6Bc4Q2"))
    }
    
    func testBtcTxBuilder() {
//        let publicKey = Data(hex: "0250863ad64a87ae8a2fe83c1af1a8403cb53f53e486d8511dad8a04887e5b2352")
//        let builder = BitcoinTransactionBuilder(walletPublicKey: publicKey,
//                                                isTestnet: false)
//        builder.bitcoinManager = BitcoinManager(networkParams: BitcoinNetwork.mainnet.networkParams, walletPublicKey: publicKey, compressedWalletPublicKey: publicKey, bip: .bip44)
//        builder.unspentOutputs = [BtcTx(tx_hash: "asdfmnbaslkdfhlkjfnasdkhfa", tx_output_n: 5, value: 5, script: "")]
//        let blockchain = Blockchain.bitcoin(testnet: false)
//        let sig = Data(repeating: UInt8(0x80), count: 64)
//        let tx = builder.buildForSend(transaction: Transaction(amount: Amount(with: blockchain, address: "1PMycacnJaSqwwJqjawXBErnLsZ7RkXUAs", type: .coin, value: 5),
//                                                               fee: Amount(with: blockchain, address: "1PMycacnJaSqwwJqjawXBErnLsZ7RkXUAs", type: .coin, value: 0.5),
//                                                               sourceAddress: "1PMycacnJaSqwwJqjawXBErnLsZ7RkXUAs",
//                                                               destinationAddress: "1PMycacnJaSqwwJqjawXBErnLsZ7RkXUAs",
//                                                               changeAddress: "1PMycacnJaSqwwJqjawXBErnLsZ7RkXUAs"),
//                                      signature: sig, hashesCount: 1)!
//
//        print(tx.count)
//        XCTAssertTrue(tx.count == 199)
    }
    
}
