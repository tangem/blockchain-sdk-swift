//
//  DynamicCompareMasterKeyTests.swift
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

class DynamicCompareMasterKeyTests: XCTestCase {
    
    // MARK: - Properties

    let addressesUtility = AddressServiceManagerUtility()
    let testVectorsUtility = TestVectorsUtility()
    
}

extension PublicKeyAddressValidatationTests {
    
    func testDynamicCompareMasterKey() {
        do {
            guard let blockchains: [BlockchainSdk.Blockchain] = try testVectorsUtility.getTestVectors(from: DecodableVectors.blockchain.rawValue) else {
                XCTFail("__INVALID_VECTOR__ BLOCKCHAIN DATA IS NIL")
                return
            }
            
            guard let vector: DecodableVectors.MnemonicVector = try testVectorsUtility.getTestVectors(
                from: DecodableVectors.publicKeyAddress.rawValue
            ) else {
                XCTFail("__INVALID_VECTOR__ PUBLIC KEY ADDRESS DATA IS NIL")
                return
            }
            
            let mnemonic = vector.main
            
            
            
            
        } catch let error {
            XCTFail("__INVALID_VECTOR__ \(error)")
            return
        }
    }
    
}
