//
//  KoinosTransactionBuilderTests.swift
//  BlockchainSdkTests
//
//  Created by Aleksei Muraveinik on 21.05.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import TangemSdk
import XCTest
@testable import BlockchainSdk

final class KoinosTransactionBuilderTests: XCTestCase {
    private let transactionBuilder = KoinosTransactionBuilder(isTestnet: false)
    private let transactionBuilderTestnet = KoinosTransactionBuilder(isTestnet: true)
    
    // MARK: Mainnet
    
    private var expectedTransaction: KoinosProtocol.Transaction {
        KoinosProtocol.Transaction(
            header: KoinosProtocol.TransactionHeader(
                chainId: "EiBZK_GGVP0H_fXVAM3j6EAuz3-B-l3ejxRSewi7qIBfSA==",
                rcLimit: 500000000,
                nonce: "KAs=",
                operationMerkleRoot: "EiBd86ETLP-Tmmq-Oj6wxfe1o2KzRGf_9LV-9O3_9Qmu8w==",
                payer: "1AYz8RCnoafLnifMjJbgNb2aeW5CbZj8Tp",
                payee: nil
            ),
            id: "0x12201042aeee64fcc89921d0b5f9bdd6c9bff3e9c089d3579c74882fe0f018acd608",
            operations: [
                KoinosProtocol.Operation(
                    callContract: KoinosProtocol.CallContractOperation(
                        contractIdBase58: "15DJN4a8SgrbGhhGksSBASiSYjGnMU8dGL",
                        entryPoint: 670398154,
                        argsBase64: "ChkAaMW2_tO2QuoaSAiMXztphDRhY2m4f6efEhkAaEFbbHucCFnoEOh3RgGrOZ38TNTI9xMWGICYmrwE"
                    )
                )
            ],
            signatures: []
        )
    }
    
    private var expectedHash: Data {
        "1042AEEE64FCC89921D0B5F9BDD6C9BFF3E9C089D3579C74882FE0F018ACD608".data(using: .hexadecimal)!
    }
    
    private var expectedSignature: String {
        "IAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
    }
    
    
    // MARK: Testnet
    
    private var expectedTransactionTestnet: KoinosProtocol.Transaction {
        KoinosProtocol.Transaction(
            header: KoinosProtocol.TransactionHeader(
                chainId: "EiBncD4pKRIQWco_WRqo5Q-xnXR7JuO3PtZv983mKdKHSQ==",
                rcLimit: 500000000,
                nonce: "KAs=",
                operationMerkleRoot: "EiCjvMCnYVk5GqAaz7D2e8LCbaJ6448pJMXS4LI_EjtW4Q==",
                payer: "1AYz8RCnoafLnifMjJbgNb2aeW5CbZj8Tp",
                payee: nil
            ),
            id: "0x1220f90ab33fcd0fa5896bb56352875eb49ac984cfd347467a50fe7a28686b11bb45",
            operations: [
                KoinosProtocol.Operation(
                    callContract: KoinosProtocol.CallContractOperation(
                        contractIdBase58: "1FaSvLjQJsCJKq5ybmGsMMQs8RQYyVv8ju",
                        entryPoint: 670398154,
                        argsBase64: "ChkAaMW2_tO2QuoaSAiMXztphDRhY2m4f6efEhkAaEFbbHucCFnoEOh3RgGrOZ38TNTI9xMWGICYmrwE"
                    )
                )
            ],
            signatures: []
        )
    }
    
    private var expectedHashTestnet: Data {
        "F90AB33FCD0FA5896BB56352875EB49AC984CFD347467A50FE7A28686B11BB45".data(using: .hexadecimal)!
    }
    
    
    // MARK: Factory
    
    private func makeTransaction(isTestnet: Bool) -> Transaction {
        Transaction(
            amount: Amount(with: .koinos(testnet: isTestnet), type: .coin, value: 12),
            fee: Fee(Amount.zeroCoin(for: .koinos(testnet: isTestnet))),
            sourceAddress: "1AYz8RCnoafLnifMjJbgNb2aeW5CbZj8Tp",
            destinationAddress: "1AWFa3VVwa2C54EU18NUDDYxjsPDwxKAuB",
            changeAddress: "1AYz8RCnoafLnifMjJbgNb2aeW5CbZj8Tp",
            params: KoinosTransactionParams(manaLimit: 5)
        )
    }
}

// MARK: Tests
extension KoinosTransactionBuilderTests {
    func testBuildForSign() throws {
        let (transaction, hash) = try transactionBuilder.buildForSign(
            transaction: makeTransaction(isTestnet: false),
            currentNonce: KoinosAccountNonce(nonce: 10)
        )
        
        XCTAssertEqual(hash, expectedHash)
        XCTAssertEqual(transaction, expectedTransaction)
    }
    
    func testBuildForSignTestnet() throws {
        let (transaction, hash) = try transactionBuilderTestnet.buildForSign(
            transaction: makeTransaction(isTestnet: true),
            currentNonce: KoinosAccountNonce(nonce: 10)
        )
        
        XCTAssertEqual(hash, expectedHashTestnet)
        XCTAssertEqual(transaction, expectedTransactionTestnet)
    }
    
    func testBuildForSend() throws {
        let signature = Data(Array(repeating: 0x00, count: 64))
        let normalizedSignature = try Secp256k1Signature(with: signature).normalize()
        
        let signedTransaction = transactionBuilder.buildForSend(
            transaction: expectedTransaction,
            normalizedSignature: normalizedSignature
        )
        
        XCTAssertEqual(signedTransaction.signatures.count, 1)
        XCTAssertEqual(signedTransaction.signatures[0], expectedSignature)
    }
}
