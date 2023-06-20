//
//  AzeroTests.swift
//  BlockchainSdkTests
//
//  Created by skibinalexander on 20.06.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import XCTest
import Combine
import CryptoKit

@testable import BlockchainSdk

class AzeroTests: XCTestCase {
    // Taken from trust wallet, `SignerTests.cpp`
    private let sizeTester = TransactionSizeTesterUtility()
    
    func testTransaction() {
        
    }
    
    private func removeSignature(image: Data, expectedImage: Data, signature: Data) -> (image: Data, expectedImage: Data) {
        let signatureRange = image.range(of: signature)!
        
        var imageWithoutSignature = image
        imageWithoutSignature.removeSubrange(signatureRange)
        var expectedImageWithoutSignature = expectedImage
        expectedImageWithoutSignature.removeSubrange(signatureRange)
        
        return (imageWithoutSignature, expectedImageWithoutSignature)
    }
    
    private func signEd25519(message: Data, privateKey: Data) throws -> Data {
        return try Curve25519.Signing.PrivateKey(rawRepresentation: privateKey).signature(for: message)
    }
}
