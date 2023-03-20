//
//  TONTests.swift
//  BlockchainSdkTests
//
//  Created by skibinalexander on 20.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import XCTest
import CryptoKit
import WalletCore

@testable import BlockchainSdk

class TONTests: XCTestCase {
    
    private var blockchain = Blockchain.ton(testnet: true)
    private let sizeTester = TransactionSizeTesterUtility()
    
    lazy var txBuilder: TONTransactionBuilder = {
        let walletPubKey = Curve25519.Signing.PrivateKey().publicKey.rawRepresentation
        let address = try! blockchain.makeAddresses(from: walletPubKey, with: nil)
        
        let wallet = Wallet(
            blockchain: blockchain,
            addresses: address,
            publicKey: .init(
                seedKey: walletPubKey,
                derivedKey: nil,
                derivationPath: nil
            )
        )
        
        return TONTransactionBuilder(wallet: wallet)
    }()
    
    func testCorrectCoinTransaction() {
        do {
            let protoInput = try txBuilder.buildForSign(
                amount: .init(with: blockchain, value: 1),
                destination: "EQAoDMgtvyuYaUj-iHjrb_yZiXaAQWSm4pG2K7rWTBj9eOC2"
            )
            
            try self.sizeTester.testTxSize(protoInput.serializedData())
        } catch {
            XCTFail("Transaction build for sign is nil")
        }
    }
    
}
