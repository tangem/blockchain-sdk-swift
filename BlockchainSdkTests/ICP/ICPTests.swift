//
//  ICPTests.swift
//  BlockchainSdkTests
//
//  Created by Dmitry Fedorov on 22.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import XCTest
import WalletCore
import TangemSdk
import IcpKit
@testable import BlockchainSdk

final class ICPTests: XCTestCase {
    private let blockchain = Blockchain.internetComputer(curve: .secp256k1)
    
    private let privateKey = WalletCore.PrivateKey(data: Data(hexString: "079E750E71A7A2680380A4744C0E84567B1F8FC3C0AFD362D8326E1E676A4A15"))!
    private lazy var publicKey = privateKey.getPublicKeySecp256k1(compressed: false)
    private let sizeTester = TransactionSizeTesterUtility()
    
    func testTransactionBuild() throws {
        let txBuilder = ICPTransactionBuilder(decimalValue: blockchain.decimalValue)
        
        let amounValueDecimal = (Decimal(10000000)) / blockchain.decimalValue
        
        let amountValue = Amount(with: blockchain, value: amounValueDecimal)
        let feeValue = Amount(with: blockchain, value: .init(stringValue: "0.0001")!)
        
        let nonce = Data(hex: "5b4210ba3969eff9b64163012d48935cf72bb86e0e444c431d28f64888af41f5")
        
        let addressService = WalletCoreAddressService(blockchain: blockchain)
        let sourceAddress = try addressService.makeAddress(
            for: Wallet.PublicKey(seedKey: publicKey.data, derivationType: nil),
            with: .default
        ).value
        
        let transaction = Transaction(
            amount: amountValue,
            fee: Fee(feeValue),
            sourceAddress: sourceAddress,
            destinationAddress: "865e1568a8928ace72592903813d0a4459c3afbdbf12a5be980371fd02751f1e",
            changeAddress: ""
        )
        
        let date = Date(timeIntervalSince1970: 1721658267)
        let input = try txBuilder.buildForSign(transaction: transaction, date: date)
        
        let requestData = try input.makeRequestData(for: publicKey.data, nonce: nonce)
        
        let hashesForSign = try input.hashes(requestData: requestData, domain: ICPDomainSeparator("ic-request"))
        
        let firstHash = try XCTUnwrap(hashesForSign[safe: 0])
        let secondHash = try XCTUnwrap(hashesForSign[safe: 1])
        
        XCTAssertEqual(firstHash.hex, "81a903f9a92fbda7164a544c6af88bc1197a8c4f56bfd68bc4ca985f9f0c1225")
        XCTAssertEqual(secondHash.hex, "a7369a37fc667fc638d0c9e0c5108287dc9d8c164859ce75c5eb6135b45f89b8")
        
        sizeTester.testTxSize(firstHash)
        sizeTester.testTxSize(secondHash)
    }
}
