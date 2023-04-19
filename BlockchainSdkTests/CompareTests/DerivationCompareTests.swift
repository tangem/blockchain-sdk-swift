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

///
class DerivationCompareTests: XCTestCase {
    
    // MARK: - Properties
    
    let blockchainUtility = BlockchainServiceManagerUtility()
    
    // MARK: - Implementation
    
    func testDerivationsFromBlockchainPath() {
        blockchainUtility.blockchains.forEach { blockchain in
            let derivation = BlockchainServiceManagerUtility.DerivationUnion(
                path: blockchain.derivationPath()?.rawPath ?? "",
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
