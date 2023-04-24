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

    let testVectorsUtility = TestVectorsUtility()
    
}

@available(iOS 13.0, *)
extension DerivationCompareTests {
    
    func testDerivationVector() {
        do {
            guard let blockchains: [BlockchainSdk.Blockchain] = try testVectorsUtility.getTestVectors(from: "blockchain_vectors") else {
                XCTFail("__INVALID_VECTOR__ BLOCKCHAIN DATA IS NIL")
                return
            }
            
            guard let vectors: [DecodableVectors.DerivationVector] = try testVectorsUtility.getTestVectors(from: "derivation_vectors") else {
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
                // TODO: - Uncomment when right derivation
//                XCTAssertEqual(vector.derivation.trust, blockchain.derivationPath(for: .new)!.rawPath, "-> \(blockchain.displayName)")
            }
        } catch let error {
            XCTFail("__INVALID_VECTOR__ \(error)")
            return
        }
    }
    
}

// Тест вектор (сид фраза, кривая, деривация с ТВ наша деривация из метода)
// Сравнить мастер ключ в тв и сдк мастер ключи одинаковые
// Сравниваем деривации
// Провалидировать адрес
// Инструкцию
