//
//  PublicKeyDerivationAddressTests.swift
//  BlockchainSdkTests
//
//  Created by skibinalexander on 25.04.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import XCTest
import CryptoKit
import TangemSdk
import WalletCore

@testable import BlockchainSdk

class PublicKeyDerivationAddressTests: XCTestCase {
    
    // MARK: - Properties

    let addressesUtility = AddressServiceManagerUtility()
    let testVectorsUtility = TestVectorsUtility()
    
}

extension PublicKeyDerivationAddressTests {
    
    func testPublicKeyDerivationAddressVector() {
        do {
            guard let blockchains: [BlockchainSdk.Blockchain] = try testVectorsUtility.getTestVectors(from: DecodableVectors.blockchain.rawValue) else {
                XCTFail("__INVALID_VECTOR__ BLOCKCHAIN DATA IS NIL")
                return
            }
            
        } catch let error {
            XCTFail("__INVALID_VECTOR__ \(error)")
            return
        }
    }
    
}
