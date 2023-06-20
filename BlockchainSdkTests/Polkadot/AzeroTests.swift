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
        let toAddress = Data(hexString: "0x8eaf04151687736326c9fea17e25fc5287613693c912909cb226aa4794f26a48")
        
        let privateKey = Data(hexString: "0xabf8e5bdbe30c65656c0a3cbd181ff8a56294a69dfedd27982aace4a76909115")
        let publicKey = try! Curve25519.Signing.PrivateKey(rawRepresentation: privateKey).publicKey.rawRepresentation
        let blockchain: Blockchain = .azero(testnet: false)
        let network: PolkadotNetwork = .init(blockchain: blockchain)!
        
        let txBuilder = PolkadotTransactionBuilder(blockchain: blockchain, walletPublicKey: publicKey, network: network)
        
        let amount = Amount(with: blockchain, value: 12345 / blockchain.decimalValue)
        let destination = try! blockchain.makeAddresses(from: toAddress, with: nil).first!.value
        let meta = PolkadotBlockchainMeta(
            specVersion: 17,
            transactionVersion: 3,
            genesisHash: "91b171bb158e2d3848fa23a9f1c25182fb8e20313b2c1eb49219da7a70ce90c3",
            blockHash: "0x343a3f4258fd92f5ca6ca5abdf473d86a78b0bcd0dc09c568ca594245cc8c642",
            nonce: 0,
            era: .init(blockNumber: 927699, period: 8)
        )
        
        let preImage = try! txBuilder.buildForSign(amount: amount, destination: destination, meta: meta)
        sizeTester.testTxSize(preImage)
        
        let signature = try! signEd25519(message: preImage, privateKey: privateKey)
        let image = try! txBuilder.buildForSend(amount: amount, destination: destination, meta: meta, signature: signature)
        
        let expectedPreImage = Data(hexString: "0500008eaf04151687736326c9fea17e25fc5287613693c912909cb226aa4794f26a48e5c032000000110000000300000091b171bb158e2d3848fa23a9f1c25182fb8e20313b2c1eb49219da7a70ce90c3343a3f4258fd92f5ca6ca5abdf473d86a78b0bcd0dc09c568ca594245cc8c642")
        let expectedImage = Data(hexString: "3102840088dc3417d5058ec4b4503e0c12ea1a0a89be200fe98922423d4334014fa6b0ee00e21967aec23f0d20809ea476bed4952b21bd537d8319158bf0ab7bf3fae1168ec6b7915388f930a4e2efd4c87b20fec513182eecbcb8f931a31cc62608e20307320000000500008eaf04151687736326c9fea17e25fc5287613693c912909cb226aa4794f26a48e5c0")
        
        XCTAssertEqual(preImage, expectedPreImage)
        
        
        let (imageWithoutSignature, expectedImageWithoutSignature) = removeSignature(image: image, expectedImage: expectedImage, signature: signature)
        XCTAssertEqual(imageWithoutSignature, expectedImageWithoutSignature)
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
