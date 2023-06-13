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
class AddressesValidationTests: XCTestCase {
    let testVectorsUtility = TestVectorsUtility()
    
    func testAddressVector() {
        do {
            guard let blockchains: [BlockchainSdk.Blockchain] = try testVectorsUtility.getTestVectors(from: "blockchain_vectors") else {
                XCTFail("__INVALID_BLOCKCHAIN__ DATA IS NIL")
                return
            }
            
            guard let vectors: [DecodableVectors.ValidAddressVector] = try testVectorsUtility.getTestVectors(from: "valid_address_vectors") else {
                XCTFail("__INVALID_VECTOR__ ADDRESSES DATA IS NIL")
                return
            }
            
            vectors.forEach { vector in
                guard let blockchain = blockchains.first(where: { $0.codingKey == vector.blockchain }) else {
                    print("__INVALID_VECTOR__ MATCH BLOCKCHAIN KEY IS NIL \(vector.blockchain)")
                    return
                }

                let coin = CoinType(blockchain)!
                let walletCoreAddressValidator = WalletCoreAddressService(coin: coin, publicKeyType: coin.publicKeyType)
                let addressValidator = AddressServiceFactory().getAddressService(for: blockchain)
                
                vector.positive.forEach {
                    XCTAssertTrue(walletCoreAddressValidator.validate($0), "__INVALIDATE_WALLET_CORE__ ADDRESS -> \(blockchain)")
                    XCTAssertTrue(addressValidator.validate($0), "__INVALIDATE_SDK_CORE__ ADDRESS -> \(blockchain)")
                }
                
                vector.negative.forEach {
                    XCTAssertFalse(walletCoreAddressValidator.validate($0), "__INVALIDATE_WALLET_CORE__ ADDRESS -> \(blockchain)")
                    XCTAssertFalse(addressValidator.validate($0), "__INVALIDATE_SDK_CORE_ ADDRESS -> \(blockchain)")
                }
            }
        } catch let error {
            XCTFail("__INVALID_VECTOR__ \(error)")
            return
        }
    }
}
