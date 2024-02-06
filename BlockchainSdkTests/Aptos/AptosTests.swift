//
//  AptosTests.swift
//  BlockchainSdkTests
//
//  Created by skibinalexander on 06.02.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

import Foundation
import XCTest
import WalletCore

@testable import BlockchainSdk

final class AptosTests: XCTestCase {
    private let blockchain: BlockchainSdk.Blockchain = .aptos(curve: .ed25519_slip0010, testnet: true)
    private let coinType: CoinType = .aptos
    
    /*
     - Use private key for aptos coin at tests in wallet-code aptos
     - Address for sender 0x07968dab936c1bad187c60ce4082f307d030d780e91e694ae03aef16aba73f30
     */
    private let privateKeyData = Data(hexString: "5d996aa76b3212142792d9130796cd2e11e3c445a93118c08414df4f66bc60ec")
    
    // MARK: - Impementation
    
    /*
     - https://github.com/trustwallet/wallet-core/blob/master/tests/chains/Aptos/CompilerTests.cpp
     */
    func testTransactionBuilder() throws {
        let privateKey = PrivateKey(data: privateKeyData)!
        let publicKey = privateKey.getPublicKeyByType(pubkeyType: .ed25519)
        
        let transactionBuilder = AptosTransactionBuilder(
            publicKey: publicKey.data,
            walletAddress: "0x7968dab936c1bad187c60ce4082f307d030d780e91e694ae03aef16aba73f30",
            isTestnet: blockchain.isTestnet,
            decimalValue: blockchain.decimalValue
        )
        
        transactionBuilder.update(sequenceNumber: 99)
        
        let amount = Amount(with: blockchain, value: 1000 / blockchain.decimalValue)
        let fee = Fee(
            Amount(
                with: blockchain, value: 3296766 / blockchain.decimalValue
            ),
            parameters: AptosFeeParams(gasUnitPrice: 100)
        )
        
        let transaction = Transaction(
            amount: amount,
            fee: fee,
            sourceAddress: "0x07968dab936c1bad187c60ce4082f307d030d780e91e694ae03aef16aba73f30",
            destinationAddress: "0x07968dab936c1bad187c60ce4082f307d030d780e91e694ae03aef16aba73f30",
            changeAddress: ""
        )
        
        let buildForSign = try transactionBuilder.buildForSign(transaction: transaction, expirationTimestamp: 3664390082)
        
        let expectedBuildForSign = "b5e97db07fa0bd0e5598aa3643a9bc6f6693bddc1a9fec9e674a461eaa00b19307968dab936c1bad187c60ce4082f307d030d780e91e694ae03aef16aba73f3063000000000000000200000000000000000000000000000000000000000000000000000000000000010d6170746f735f6163636f756e74087472616e7366657200022007968dab936c1bad187c60ce4082f307d030d780e91e694ae03aef16aba73f3008e803000000000000fe4d3200000000006400000000000000c2276ada0000000021"
        
        XCTAssertEqual(buildForSign.hexString.lowercased(), expectedBuildForSign)
    }
    
}
