//
//  TronTests.swift
//  BlockchainSdkTests
//
//  Created by Andrey Chukavin on 27.04.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import XCTest

class TronTests: XCTestCase {
    var blockchain: Blockchain!
    var txBuilder: TronTransactionBuilder!
    
    let tronBlock = TronBlock(
        block_header: .init(
            raw_data: .init(
                number: 3111739,
                txTrieRoot: "64288c2db0641316762a99dbb02ef7c90f968b60f9f2e410835980614332f86d",
                witness_address: "415863f6091b8e71766da808b1dd3159790f61de7d",
                parentHash: "00000000002f7b3af4f5f8b9e23a30c530f719f165b742e7358536b280eead2d",
                version: 3,
                timestamp: 1539295479000
            )
        )
    )
    
    override func setUp() {
        self.blockchain = Blockchain.tron(testnet: true)
        self.txBuilder = TronTransactionBuilder(blockchain: blockchain)
    }
    
    func testTrxTransfer() {
        let transactionRaw = try! txBuilder.buildForSign(amount: Amount(with: blockchain, value: 1), source: "TU1BRXbr6EmKmrLL4Kymv7Wp18eYFkRfAF", destination: "TXXxc9NsHndfQ2z9kMKyWpYa5T3QbhKGwn", block: tronBlock)
        
        let signature = Data(hex: "6b5de85a80b2f4f02351f691593fb0e49f14c5cb42451373485357e42d7890cd77ad7bfcb733555c098b992da79dabe5050f5e2db77d9d98f199074222de037701")
        let transaction = txBuilder.buildForSend(rawData: transactionRaw, signature: signature)
        let transactionData = try! transaction.serializedData()
        
        let expectedTransactionData = Data(hex: "0a85010a027b3b2208b21ace8d6ac20e7e40d8abb9bae62c5a67080112630a2d747970652e676f6f676c65617069732e636f6d2f70726f746f636f6c2e5472616e73666572436f6e747261637412320a1541c5d1c75825b30bb2e2e655798209d56448eb6b5e121541ec8c5a0fcbb28f14418eed9cf582af0d77e4256e18c0843d70d889a4a9e62c12416b5de85a80b2f4f02351f691593fb0e49f14c5cb42451373485357e42d7890cd77ad7bfcb733555c098b992da79dabe5050f5e2db77d9d98f199074222de037701")
        
        XCTAssertEqual(transactionData, expectedTransactionData)
    }
    
    func testTrc20Transfer() {
        let token = Token(name: "Tether",
                          symbol: "USDT",
                          contractAddress: "TXLAQ63Xg1NAzckPwKHvzw7CSEmLMEqcdj",
                          decimalCount: 6)
        
        let transactionRaw = try! txBuilder.buildForSign(amount: Amount(with: token, value: 1), source: "TU1BRXbr6EmKmrLL4Kymv7Wp18eYFkRfAF", destination: "TXXxc9NsHndfQ2z9kMKyWpYa5T3QbhKGwn", block: tronBlock)
        
        let signature = Data(hex: "6b5de85a80b2f4f02351f691593fb0e49f14c5cb42451373485357e42d7890cd77ad7bfcb733555c098b992da79dabe5050f5e2db77d9d98f199074222de037701")
        let transaction = txBuilder.buildForSend(rawData: transactionRaw, signature: signature)
        let transactionData = try! transaction.serializedData()
        
        let expectedTransactionData = Data(hex: "0ad3010a027b3b2208b21ace8d6ac20e7e40d8abb9bae62c5aae01081f12a9010a31747970652e676f6f676c65617069732e636f6d2f70726f746f636f6c2e54726967676572536d617274436f6e747261637412740a1541c5d1c75825b30bb2e2e655798209d56448eb6b5e121541ea51342dabbb928ae1e576bd39eff8aaf070a8c62244a9059cbb000000000000000000000041ec8c5a0fcbb28f14418eed9cf582af0d77e4256e00000000000000000000000000000000000000000000000000000000000f424070d889a4a9e62c900180b4891312416b5de85a80b2f4f02351f691593fb0e49f14c5cb42451373485357e42d7890cd77ad7bfcb733555c098b992da79dabe5050f5e2db77d9d98f199074222de037701")
        
        XCTAssertEqual(transactionData, expectedTransactionData)
    }
}
