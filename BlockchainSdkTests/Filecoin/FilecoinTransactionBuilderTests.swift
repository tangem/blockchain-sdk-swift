//
//  FilecoinTransactionBuilderTests.swift
//  BlockchainSdkTests
//
//  Created by Aleksei Muraveinik on 29.08.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import XCTest
import WalletCore
@testable import BlockchainSdk

final class FilecoinTransactionBuilderTests: XCTestCase {
    private enum Constants {
        static let publicKey = Data(hex: "0374D0F81F42DDFE34114D533E95E6AE5FE6EA271C96F1FA505199FDC365AE9720")
        static let signature = Data(hex: "06881E97DA3DCEF5D44FEB02FA75697221B21DF071586E95E3EC4E6B03FA62B014D4E21B89FBC41E9453FC495A92FD97EA6" +
                                    "7D491B433A5AAEF7361F22416D74701")
                
        static let transaction = Transaction(
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
                    gasUnitPrice: 101225,
                    gasLimit: 1526328,
                    gasPremium: 50612
                )
            ),
            sourceAddress: "f1hbyibpq4mea6l3no7aag24hxpwgf4zwp6msepwi",
            destinationAddress: "f1rluskhwvv5b3z36skltu4noszbc5stfihevbf2i",
            changeAddress: "f1hbyibpq4mea6l3no7aag24hxpwgf4zwp6msepwi"
        )
    }
    
    private let transactionBuilder = FilecoinTransactionBuilder(
        wallet: Wallet(
            blockchain: .filecoin,
            addresses: [
                .default: PlainAddress(
                    value: "f1hbyibpq4mea6l3no7aag24hxpwgf4zwp6msepwi",
                    publicKey: Wallet.PublicKey(
                        seedKey: Constants.publicKey,
                        derivationType: nil
                    ),
                    type: .default
                )
            ]
        )
    )
    
    func testBuildForSign() throws {
        let expected = Data(hex: "BEB93CCF5C85273B327AC5DCDD58CBF3066F57FC84B87CD20DC67DF69EC2D0A9")

        let nonce: UInt64 = 2
        let actual = try transactionBuilder.buildForSign(
            transaction: Constants.transaction,
            nonce: nonce
        )
        
        XCTAssertEqual(expected, actual)
    }
    
    func testBuildForSend() throws {
        let expected = FilecoinSignedTransactionBody(
            transactionBody: FilecoinTransactionBody(
                // Why this source address differs from the one from transaction
                sourceAddress: "f1flbddhx4vwox3y3ux5bwgsgq2frzeiuvvdrjo7i",
                destinationAddress: "f1rluskhwvv5b3z36skltu4noszbc5stfihevbf2i",
                amount: "10000000000000000",
                nonce: 2,
                gasUnitPrice: "101225",
                gasLimit: 1526328,
                gasPremium: "50612"
            ),
            signature: FilecoinSignedTransactionBody.Signature(
                type: 1,
                signature: "Bogel9o9zvXUT+sC+nVpciGyHfBxWG6V4+xOawP6YrAU1OIbifvEHpRT/Elakv2X6mfUkbQzparvc2HyJBbXRwE="
            )
        )
        
        let nonce: UInt64 = 2
        let transaction = Constants.transaction
        
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
