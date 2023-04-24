//
//  CoinAddressCompareTests.swift
//  BlockchainSdkTests
//
//  Created by skibinalexander on 28.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import XCTest
import CryptoKit
import TangemSdk
import WalletCore

@testable import BlockchainSdk

/// Basic testplan for testing validation Addresses blockchain with compare addreses from TrustWallet address service and Local address service
class CoinAddressesCompareTests: XCTestCase {
    
    let addressesUtility = AddressServiceManagerUtility()
    let testVectorsUtility = TestVectorsUtility()
    
}

extension CoinAddressesCompareTests {
    
    struct Vector: Decodable {
        let blockchain: String
        let positive: [String]
        let negative: [String]
    }
    
}

// MARK: - Compare Addresses from address string

@available(iOS 13.0, *)
extension CoinAddressesCompareTests {
    
    func testAddressVector() {
        do {
            guard let blockchains: [BlockchainSdk.Blockchain] = try testVectorsUtility.getTestVectors(from: "blockchain_vectors") else {
                XCTFail("__INVALID_VECTOR__ BLOCKCHAIN DATA IS NIL")
                return
            }
            
            guard let vectors: [Vector] = try testVectorsUtility.getTestVectors(from: "addresses_compare_vectors") else {
                XCTFail("__INVALID_VECTOR__ ADDRESSES DATA IS NIL")
                return
            }
            
            vectors.forEach { vector in
                guard let blockchain = blockchains.first(where: { $0.codingKey == vector.blockchain }) else {
                    print("__INVALID_VECTOR__ MATCH BLOCKCHAIN KEY IS NIL \(vector.blockchain)")
                    return
                }
                
                vector.positive.forEach {
                    XCTAssertTrue(TrustWalletAddressService.validate($0, for: blockchain), "-> \(blockchain)")
                    XCTAssertTrue(blockchain.getAddressService().validate($0), "-> \(blockchain)")
                }
                
                vector.negative.forEach {
                    XCTAssertFalse(TrustWalletAddressService.validate($0, for: blockchain), "-> \(blockchain)")
                    XCTAssertFalse(blockchain.getAddressService().validate($0), "-> \(blockchain)")
                }
            }
        } catch let error {
            XCTFail("__INVALID_VECTOR__ \(error)")
            return
        }
    }
    
}
