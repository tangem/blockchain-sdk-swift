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
    private let blockchain: BlockchainSdk.Blockchain = .algorand(curve: .ed25519_slip0010, testnet: false)
    private let coinType: CoinType = .algorand
    private let privateKeyData = Data(hexString: "d5b43d706ef0cb641081d45a2ec213b5d8281f439f2425d1af54e2afdaabf55b")
    
    // MARK: - Impementation
    
    func testCoreExample() throws {
        let privateKey = PrivateKey(data: privateKeyData)!
        
        let round: UInt64 = 1937767
        let transaction = AlgorandTransfer.with {
            $0.toAddress = "CRLADAHJZEW2GFY2UPEHENLOGCUOU74WYSTUXQLVLJUJFHEUZOHYZNWYR4"
            $0.amount = 1000000000000
        }
        let input = AlgorandSigningInput.with {
            $0.privateKey = privateKey.data
            $0.genesisID = "mainnet-v1.0"
            $0.genesisHash = Data(base64Encoded: "wGHE2Pwdvd7S12BL5FaOP20EGYesN73ktiC1qzkkit8=")!
            $0.note = "hello".data(using: .utf8)!
            $0.firstRound = round
            $0.lastRound = round + 1000
            $0.fee = 263000
            $0.transfer = transaction
        }
        
        let output: AlgorandSigningOutput = AnySigner.sign(input: input, coin: .algorand)
        
        XCTAssertEqual(output.encoded.hexString.lowercased(), "82a3736967c440baa00062adcdcb5875e4435cdc6885d26bfe5308ab17983c0fda790b7103051fcb111554e5badfc0ac7edf7e1223a434342a9eeed5cdb047690827325051560ba374786e8aa3616d74cf000000e8d4a51000a3666565ce00040358a26676ce001d9167a367656eac6d61696e6e65742d76312e30a26768c420c061c4d8fc1dbdded2d7604be4568e3f6d041987ac37bde4b620b5ab39248adfa26c76ce001d954fa46e6f7465c40568656c6c6fa3726376c42014560180e9c92da3171aa3c872356e30a8ea7f96c4a74bc1755a68929c94cb8fa3736e64c42061bf060efc02e2887dfffc8ed85268c8c091c013eedf315bc50794d02a8791ada474797065a3706179")
    }
    
    func testTransactionBuilder() throws {
        let privateKey = PrivateKey(data: privateKeyData)!
        
        let transactionBuilder = AlgorandTransactionBuilder(
            publicKey: privateKey.getPublicKeyByType(pubkeyType: .ed25519).data,
            curve: .ed25519_slip0010,
            isTestnet: blockchain.isTestnet
        )
        
        let amount = Amount(with: blockchain, value: 10000 / blockchain.decimalValue)
        let fee = Fee(Amount(with: blockchain, value: 1000 / blockchain.decimalValue))
        
        let transaction = Transaction(
            amount: amount,
            fee: fee,
            sourceAddress: "",
            destinationAddress: "CRLADAHJZEW2GFY2UPEHENLOGCUOU74WYSTUXQLVLJUJFHEUZOHYZNWYR4",
            changeAddress: ""
        )
        
        let round: UInt64 = 35240112
        
        let buildParameters = AlgorandBuildParams(
            genesisId: "mainnet-v1.0",
            genesisHash: "wGHE2Pwdvd7S12BL5FaOP20EGYesN73ktiC1qzkkit8=",
            firstRound: round,
            lastRound: round + 1000,
            nonce: "hello"
        )
        
        let buildForSign = try transactionBuilder.buildForSign(
            transaction: transaction,
            with: buildParameters
        )
        
        let expectedBuildForSign = "54588AA3616D74CD2710A3666565CD03E8A26676CE0219B8B0A367656EAC6D61696E6E65742D76312E30A26768C420C061C4D8FC1DBDDED2D7604BE4568E3F6D041987AC37BDE4B620B5AB39248ADFA26C76CE0219BC98A46E6F7465C40568656C6C6FA3726376C42014560180E9C92DA3171AA3C872356E30A8EA7F96C4A74BC1755A68929C94CB8FA3736E64C42061BF060EFC02E2887DFFFC8ED85268C8C091C013EEDF315BC50794D02A8791ADA474797065A3706179"
        
        XCTAssertEqual(buildForSign.hexString, expectedBuildForSign)
        
        let signature = privateKey.sign(digest: buildForSign, curve: .ed25519)
        
        let buildForSend = try transactionBuilder.buildForSend(
            transaction: transaction,
            with: buildParameters,
            signature: signature!
        )
        
        let exexpectedBuildForSend = "82A3736967C4402556BBE3CB6498A8D375ECED4092614C70DC05AAE715B9A0E6EDB0717CC2AAFFA4B2C8FCFBD6C11373654712E4BE297C44139B1A8A147EEECEE0E3F338299904A374786E8AA3616D74CD2710A3666565CD03E8A26676CE0219B8B0A367656EAC6D61696E6E65742D76312E30A26768C420C061C4D8FC1DBDDED2D7604BE4568E3F6D041987AC37BDE4B620B5AB39248ADFA26C76CE0219BC98A46E6F7465C40568656C6C6FA3726376C42014560180E9C92DA3171AA3C872356E30A8EA7F96C4A74BC1755A68929C94CB8FA3736E64C42061BF060EFC02E2887DFFFC8ED85268C8C091C013EEDF315BC50794D02A8791ADA474797065A3706179"
        
        XCTAssertEqual(buildForSend.hexString, exexpectedBuildForSend)
    }
    
}
