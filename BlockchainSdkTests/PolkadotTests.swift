//
//  PolkadotTests.swift
//  BlockchainSdkTests
//
//  Created by Andrey Chukavin on 04.02.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import XCTest
import Combine
import CryptoKit

class PolkadotTests: XCTestCase {
    // Taken from trust wallet, `SignerTests.cpp`
    
    func testTransaction72dd5b() {
        let privateKey = Data(hexString: "37932b086586a6675e66e562fe68bd3eeea4177d066619c602fe3efc290ada62")
        let publicKey = try! Curve25519.Signing.PrivateKey(rawRepresentation: privateKey).publicKey.rawRepresentation
        let network: PolkadotNetwork = .polkadot
        let blockchain = network.blockchain
        
        let txBuilder = PolkadotTransactionBuilder(walletPublicKey: publicKey, network: network)
        
        let amount = Amount(with: blockchain, value: 1)
        let destination = "13ZLCqJNPsRZYEbwjtZZFpWt9GyFzg5WahXCVWKpWdUJqrQ5"
        let meta = PolkadotBlockchainMeta(
            specVersion: 28,
            transactionVersion: 6,
            genesisHash: "91b171bb158e2d3848fa23a9f1c25182fb8e20313b2c1eb49219da7a70ce90c3",
            blockHash: "7d5fa17b70251d0806f26156b1b698dfd09e040642fa092595ce0a78e9e84fcd",
            nonce: 1,
            era: .init(blockNumber: 3910736, period: 64)
        )
        
        let preImage = try! txBuilder.buildForSign(amount: amount, destination: destination, meta: meta)
        let signature = try! privateKey.sign(privateKey: privateKey)
        let image = try! txBuilder.buildForSend(amount: amount, destination: destination, meta: meta, signature: signature)

        let expectedPreImage = Data(hexString: "0500007120f76076bcb0efdf94c7219e116899d0163ea61cb428183d71324eb33b2bce0700e40b5402050104001c0000000600000091b171bb158e2d3848fa23a9f1c25182fb8e20313b2c1eb49219da7a70ce90c37d5fa17b70251d0806f26156b1b698dfd09e040642fa092595ce0a78e9e84fcd")
        let expectedImage = Data(hexString: "410284008d96660f14babe708b5e61853c9f5929bc90dd9874485bf4d6dc32d3e6f22eaa0038ec4973ab9773dfcbf170b8d27d36d89b85c3145e038d68914de83cf1f7aca24af64c55ec51ba9f45c5a4d74a9917dee380e9171108921c3e5546e05be15206050104000500007120f76076bcb0efdf94c7219e116899d0163ea61cb428183d71324eb33b2bce0700e40b5402")
        
        XCTAssertEqual(preImage, expectedPreImage)
        
     
        let signatureRange = image.range(of: signature)!
        var imageWithoutSignature = image
        imageWithoutSignature.removeSubrange(signatureRange)
        var expectedImageWithoutSignature = expectedImage
        expectedImageWithoutSignature.removeSubrange(signatureRange)
     
        XCTAssertEqual(imageWithoutSignature, expectedImageWithoutSignature)
    }
}
