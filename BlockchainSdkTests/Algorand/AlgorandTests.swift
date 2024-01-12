//
//  AlgorandTests.swift
//  BlockchainSdkTests
//
//  Created by skibinalexander on 28.12.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import XCTest
import WalletCore

@testable import BlockchainSdk

final class AlgorandTests: XCTestCase {
    private let blockchain: BlockchainSdk.Blockchain = .algorand(testnet: false)
    private let round: UInt64 = 1937767
    private let privateKeyData = Data(hexString: "d5b43d706ef0cb641081d45a2ec213b5d8281f439f2425d1af54e2afdaabf55b")
    
    // MARK: - Impementation
    
    func testWalletCoreExample() throws {
        let privateKey = PrivateKey(data: privateKeyData)!
        
        let round: UInt64 = 1937767
        let transaction = AlgorandTransfer.with {
            $0.toAddress = "CRLADAHJZEW2GFY2UPEHENLOGCUOU74WYSTUXQLVLJUJFHEUZOHYZNWYR4"
            $0.amount = 1000000000000
        }
        let input = AlgorandSigningInput.with {
            $0.publicKey = privateKey.getPublicKeyEd25519().data
            $0.genesisID = "mainnet-v1.0"
            $0.genesisHash = Data(base64Encoded: "wGHE2Pwdvd7S12BL5FaOP20EGYesN73ktiC1qzkkit8=")!
            $0.note = "hello".data(using: .utf8)!
            $0.firstRound = round
            $0.lastRound = round + 1000
            $0.fee = 263000
            $0.transfer = transaction
        }
        
        let txInputData = try input.serializedData()
        
        guard !txInputData.isEmpty else {
            throw WalletError.failedToBuildTx
        }
        
        guard !txInputData.isEmpty else {
            throw WalletError.failedToBuildTx
        }

        let preImageHashes = TransactionCompiler.preImageHashes(coinType: .algorand, txInputData: txInputData)
        let output = try TxCompilerPreSigningOutput(serializedData: preImageHashes)

        guard output.error == .ok else {
            throw WalletError.failedToBuildTx
        }
        
        try print(output.serializedData().hexString)
        
//        let output: AlgorandSigningOutput = AnySigner.sign(input: txInputData.ser, coin: .algorand)
        
//        XCTAssertEqual(output.encoded.hexString.lowercased(), "82a3736967c440baa00062adcdcb5875e4435cdc6885d26bfe5308ab17983c0fda790b7103051fcb111554e5badfc0ac7edf7e1223a434342a9eeed5cdb047690827325051560ba374786e8aa3616d74cf000000e8d4a51000a3666565ce00040358a26676ce001d9167a367656eac6d61696e6e65742d76312e30a26768c420c061c4d8fc1dbdded2d7604be4568e3f6d041987ac37bde4b620b5ab39248adfa26c76ce001d954fa46e6f7465c40568656c6c6fa3726376c42014560180e9c92da3171aa3c872356e30a8ea7f96c4a74bc1755a68929c94cb8fa3736e64c42061bf060efc02e2887dfffc8ed85268c8c091c013eedf315bc50794d02a8791ada474797065a3706179")
    }
    
    func testTransactionBuilder() throws {
        let transactionBuilder = AlgorandTransactionBuilder(isTestnet: blockchain.isTestnet)
        
        let privateKey = PrivateKey(data: privateKeyData)!
        let amount = Amount(with: blockchain, value: Decimal(1000000000000) / blockchain.decimalValue)
        let fee = Fee(Amount(with: blockchain, value: Decimal(263000) / blockchain.decimalValue))
        
        let transaction = Transaction(
            amount: amount,
            fee: fee,
            sourceAddress: "",
            destinationAddress: "CRLADAHJZEW2GFY2UPEHENLOGCUOU74WYSTUXQLVLJUJFHEUZOHYZNWYR4",
            changeAddress: ""
        )
        
        let buildForSign = try transactionBuilder.buildForSign(
            transaction: transaction,
            with: .init(
                publicKey: BlockchainSdk.Wallet.PublicKey(seedKey: privateKey.getPublicKeyEd25519().data, derivationType: nil),
                genesisId: "mainnet-v1.0",
                genesisHash: "wGHE2Pwdvd7S12BL5FaOP20EGYesN73ktiC1qzkkit8=",
                round: 1937767,
                lastRound: 1937767 + 1000,
                nonce: "hello"
            )
        )
    }
    
}
