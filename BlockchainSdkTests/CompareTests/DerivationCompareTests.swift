//
//  DerivationCompareTests.swift
//  BlockchainSdkTests
//
//  Created by skibinalexander on 19.04.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import XCTest
import CryptoKit
import TangemSdk
import WalletCore

@testable import BlockchainSdk

class DerivationCompareTests: XCTestCase {
    
    // MARK: - Properties
    
    let blockchainUtility = BlockchainServiceManagerUtility()
    let testVectorsUtility = TestVectorsUtility()
    
    // MARK: - Implementation
    
    func testDerivationsFromBlockchainPath() {
        blockchainUtility.blockchains.forEach { blockchain in
            let derivation = BlockchainServiceManagerUtility.DerivationUnion(
                path: blockchain.derivationPath(for: .new)?.rawPath ?? "",
                blockchain: blockchain
            )

            guard let sdkReference = blockchainUtility.sdkDerivations.first(where: { $0.blockchain == derivation.blockchain }) else {
                XCTFail("__INVALID_TANGEM_SDK_DERIVATION_NOT_FOUND__ BLOCKCHAIN -> \(blockchain.displayName)")
                return
            }

            // Validate with sdkReference
            XCTAssertEqual(sdkReference.path, derivation.path, "\(derivation.debugDescription)")

            // Validate with twReference
            if CoinType(derivation.blockchain) != nil {
                guard let twReference = blockchainUtility.twDerivations.first(where: { $0.blockchain == derivation.blockchain }) else {
                    XCTFail("__INVALID_TW_DERIVATION_NOT_FOUND__ BLOCKCHAIN -> \(blockchain.displayName)")
                    return
                }

                XCTAssertEqual(twReference.path, derivation.path, "\(derivation.debugDescription)")
            }
        }
    }
    
    func testDerivationsForBlockchain() {
        blockchainUtility.blockchains.forEach { blockchain in
            let derivation = BlockchainServiceManagerUtility.DerivationUnion(
                path: blockchain.derivationPath()?.rawPath ?? "",
                blockchain: blockchain
            )

            guard let sdkReference = blockchainUtility.sdkDerivations.first(where: { $0.blockchain == derivation.blockchain }) else {
                XCTFail("__INVALID_TANGEM_SDK_DERIVATION_NOT_FOUND__ BLOCKCHAIN -> \(blockchain.displayName)")
                return
            }

            // Validate with twReference
            if CoinType(derivation.blockchain) != nil {
                guard let twReference = blockchainUtility.twDerivations.first(where: { $0.blockchain == derivation.blockchain }) else {
                    XCTFail("__INVALID_TW_DERIVATION_NOT_FOUND__ BLOCKCHAIN -> \(blockchain.displayName)")
                    return
                }

                XCTAssertEqual(twReference.path, sdkReference.path, "\(derivation.debugDescription)")
            }
        }
    }
    
}

extension DerivationCompareTests {
    
    struct Vector: Decodable {
        
        struct Derivation: Decodable {
            let tangem: String
            let trust: String
        }
        
        // MARK: - Properties
        
        let blockchain: String
        let derivation: Derivation
        
    }
    
}

@available(iOS 13.0, *)
extension DerivationCompareTests {
    
    func testDerivationVector() {
        do {
            guard let blockchains: [BlockchainSdk.Blockchain] = try testVectorsUtility.getTestVectors(from: "blockchain_vectors") else {
                XCTFail("__INVALID_VECTOR__ BLOCKCHAIN DATA IS NIL")
                return
            }
            
            guard let vectors: [Vector] = try testVectorsUtility.getTestVectors(from: "derivation_vectors") else {
                XCTFail("__INVALID_VECTOR__ DERIVATION DATA IS NIL")
                return
            }
            
            vectors.forEach { vector in
                guard let blockchain = blockchains.first(where: { $0.codingKey == vector.blockchain }) else {
                    print("__INVALID_VECTOR__ MATCH BLOCKCHAIN KEY IS NIL \(vector.blockchain)")
                    return
                }
                
                // Validate with TangemSdk Derivation
                XCTAssertEqual(vector.derivation.tangem, blockchain.derivationPath(for: .new)?.rawPath, "-> \(blockchain)")
                
                // Validate with TrustWallet Derivation
                XCTAssertEqual(vector.derivation.trust, blockchain.derivationPath(for: .new)!.rawPath, "-> \(blockchain.displayName)")
            }
        } catch let error {
            XCTFail("__INVALID_VECTOR__ \(error)")
            return
        }
    }
    
}
