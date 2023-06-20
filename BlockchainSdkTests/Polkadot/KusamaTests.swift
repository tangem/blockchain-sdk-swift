//
//  KusamaTests.swift
//  BlockchainSdkTests
//
//  Created by skibinalexander on 20.06.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import XCTest
import Combine
import CryptoKit

@testable import BlockchainSdk

class KusamaTests: XCTestCase {
    // Taken from trust wallet, `SignerTests.cpp`
    private let sizeTester = TransactionSizeTesterUtility()
    
    func testTransaction() {
//        let toAddress = Data(hexString: "0x8eaf04151687736326c9fea17e25fc5287613693c912909cb226aa4794f26a48")
//
//        let privateKey = Data(hexString: "0xabf8e5bdbe30c65656c0a3cbd181ff8a56294a69dfedd27982aace4a76909115")
//        let publicKey = try! Curve25519.Signing.PrivateKey(rawRepresentation: privateKey).publicKey.rawRepresentation
//        let blockchain: Blockchain = .kusama
//        let network: PolkadotNetwork = .init(blockchain: blockchain)!
        
        // TODO: - Implement compare Build / Sign transaction for blockchain Kusama
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
