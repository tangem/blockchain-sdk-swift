//
//  FilecoinTransactionBuilderTests.swift
//  BlockchainSdkTests
//
//  Created by Aleksei Muraveinik on 29.08.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import XCTest
@testable import BlockchainSdk

final class FilecoinTransactionBuilderTests: XCTestCase {
    private let transactionBuilder = FilecoinTransactionBuilder(
        wallet: Wallet(
            blockchain: .filecoin,
            addresses: [
                .default: PlainAddress(
                    value: Constants.sourceAddress,
                    publicKey: Wallet.PublicKey(
                        seedKey: Constants.publicKey,
                        derivationType: nil
                    ),
                    type: .default
                )
            ]
        )
    )
    
    private var transaction: Transaction {
        Transaction(
            amount: Amount(
                with: .filecoin,
                type: .coin,
                value: 0.01
            ),
            fee: Fee(
                Amount(
                    with: .filecoin,
                    type: .coin,
                    value: (101225 * 1526328) / Blockchain.filecoin.decimalValue
                ),
                parameters: FilecoinFeeParameters(
                    gasLimit: 1526328,
                    gasFeeCap: 101225,
                    gasPremium: 50612
                )
            ),
            sourceAddress: Constants.sourceAddress,
            destinationAddress: Constants.destinationAddress,
            changeAddress: Constants.sourceAddress
        )
    }
    
    func testBuildForSign() throws {
        let expected = Data(hex: "BEB93CCF5C85273B327AC5DCDD58CBF3066F57FC84B87CD20DC67DF69EC2D0A9")
        let actual = try transactionBuilder.buildForSign(transaction: transaction, nonce: 2)
        
        XCTAssertEqual(expected, actual)
    }
    
    func testBuildForSend() throws {
        let nonce: UInt64 = 2
        let expected = FilecoinSignedMessage(
            message: FilecoinMessage(
                from: Constants.sourceAddress,
                to: Constants.destinationAddress,
                value: "10000000000000000",
                nonce: nonce,
                gasLimit: 1526328,
                gasFeeCap: "101225",
                gasPremium: "50612"
            ),
            signature: FilecoinSignedMessage.Signature(
                type: 1,
                data: "Bogel9o9zvXUT+sC+nVpciGyHfBxWG6V4+xOawP6YrAU1OIbifvEHpRT/Elakv2X6mfUkbQzparvc2HyJBbXRwE="
            )
        )
        
        let hashToSign = try transactionBuilder.buildForSign(transaction: transaction, nonce: nonce)
        
        let actual = try transactionBuilder.buildForSend(
            transaction: transaction,
            nonce: nonce,
            signatureInfo: SignatureInfo(
                signature: Constants.signature,
                publicKey: Constants.publicKey,
                hash: hashToSign
            )
        )
        
        XCTAssertEqual(expected, actual)
    }
}

private extension FilecoinTransactionBuilderTests {
    enum Constants {
        static let publicKey = Data(hex: "0374D0F81F42DDFE34114D533E95E6AE5FE6EA271C96F1FA505199FDC365AE9720")
        static let signature = Data(hex: "06881E97DA3DCEF5D44FEB02FA75697221B21DF071586E95E3EC4E6B03FA62B014D4E21B89FBC41E9453FC495A92FD97EA67D491B433A5AAEF7361F22416D74701")
                
        static let sourceAddress = "f1flbddhx4vwox3y3ux5bwgsgq2frzeiuvvdrjo7i"
        static let destinationAddress = "f1rluskhwvv5b3z36skltu4noszbc5stfihevbf2i"
    }
}
