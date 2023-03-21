//
//  TONTests.swift
//  BlockchainSdkTests
//
//  Created by skibinalexander on 20.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import XCTest
import CryptoKit
import TangemSdk
import WalletCore

@testable import BlockchainSdk

class TONTests: XCTestCase {
    
    private var blockchain = Blockchain.ton(testnet: true)
    private var privateKey = Curve25519.Signing.PrivateKey()
    
    lazy var walletManager: TONWalletManager = {
        let walletPubKey = privateKey.publicKey.rawRepresentation
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
        
        return try! .init(
            wallet: wallet,
            networkService: TONNetworkService(providers: [], blockchain: blockchain)
        )
    }()
    
    lazy var txBuilder: TONTransactionBuilder = {
        return TONTransactionBuilder(wallet: walletManager.wallet)
    }()
    
    func testCorrectCoinTransaction() {
        do {
            let input = try txBuilder.buildForSign(
                amount: .init(with: blockchain, value: 1),
                destination: "EQAoDMgtvyuYaUj-iHjrb_yZiXaAQWSm4pG2K7rWTBj9eOC2"
            )
            
            let _ = try walletManager.buildTransaction(
                input: input,
                with: TrustCoreSignerTesterUtility(privateKey: privateKey)
            )
            
            // TODO: - Next Write correct output for compare
        } catch {
            XCTFail("Transaction build for sign is nil")
        }
    }
    
}
