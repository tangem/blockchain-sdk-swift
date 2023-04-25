//
//  KeyAddressesCompareTests.swift
//  BlockchainSdkTests
//
//  Created by skibinalexander on 04.04.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import XCTest
import CryptoKit
import TangemSdk
import WalletCore

@testable import BlockchainSdk

class PublicKeyAddressValidatationTests: XCTestCase {
    
    // MARK: - Properties

    let addressesUtility = AddressServiceManagerUtility()
    let testVectorsUtility = TestVectorsUtility()
    
}

extension PublicKeyAddressValidatationTests {
    
    func testPublicKeyAddressVector() {
        do {
            guard let blockchains: [BlockchainSdk.Blockchain] = try testVectorsUtility.getTestVectors(from: DecodableVectors.blockchain.rawValue) else {
                XCTFail("__INVALID_VECTOR__ BLOCKCHAIN DATA IS NIL")
                return
            }
            
            guard let vectors: [DecodableVectors.PublicKeyAddressVector] = try testVectorsUtility.getTestVectors(
                from: DecodableVectors.publicKeyAddress.rawValue
            ) else {
                XCTFail("__INVALID_VECTOR__ PUBLIC KEY ADDRESS DATA IS NIL")
                return
            }
            
            try vectors.forEach { vector in
                guard let blockchain = blockchains.first(where: { $0.codingKey == vector.blockchain }) else {
                    print("__INVALID_VECTOR__ MATCH BLOCKCHAIN KEY IS NIL \(vector.blockchain)")
                    return
                }
                
                let publicKey = Data(hex: vector.publicKey)

                let addressFromPublicKey = try addressesUtility.makeLocalWalletAddressService(publicKey: publicKey, for: blockchain)
                let addressFromTrustWallet = try addressesUtility.makeTrustWalletAddressService(publicKey: publicKey, for: blockchain)

                XCTAssertTrue(TrustWalletAddressService.validate(vector.address, for: blockchain), "-> \(blockchain)")
                XCTAssertEqual(addressFromPublicKey, addressFromTrustWallet, "-> \(blockchain.displayName)!")
                XCTAssertEqual(vector.address, addressFromPublicKey, "\(blockchain.displayName)!")
            }
        } catch let error {
            XCTFail("__INVALID_VECTOR__ \(error)")
            return
        }
    }
    
}
