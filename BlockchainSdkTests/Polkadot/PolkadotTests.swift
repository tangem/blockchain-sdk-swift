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

@testable import BlockchainSdk

class PolkadotTests: XCTestCase {
    // Taken from trust wallet, `SignerTests.cpp`
    private let sizeTester = TransactionSizeTesterUtility()
    
    func testTransaction9fd062() {
        let privateKey = Data(hexString: "70a794d4f1019c3ce002f33062f45029c4f930a56b3d20ec477f7668c6bbc37f")
        let publicKey = try! Curve25519.Signing.PrivateKey(rawRepresentation: privateKey).publicKey.rawRepresentation
        let network: PolkadotNetwork = .polkadot
        let blockchain: Blockchain = .polkadot(testnet: false)
        
        let txBuilder = PolkadotTransactionBuilder(blockchain: blockchain, walletPublicKey: publicKey, network: network)
        
        let amount = Amount(with: blockchain, value: 0.2)
        let destination = "13ZLCqJNPsRZYEbwjtZZFpWt9GyFzg5WahXCVWKpWdUJqrQ5"
        let meta = PolkadotBlockchainMeta(
            specVersion: 26,
            transactionVersion: 5,
            genesisHash: "91b171bb158e2d3848fa23a9f1c25182fb8e20313b2c1eb49219da7a70ce90c3",
            blockHash: "0x5d2143bb808626d63ad7e1cda70fa8697059d670a992e82cd440fbb95ea40351",
            nonce: 3,
            era: .init(blockNumber: 3541050, period: 64)
        )
        
        let preImage = try! txBuilder.buildForSign(amount: amount, destination: destination, meta: meta)
        sizeTester.testTxSize(preImage)
        
        let signature = try! signEd25519(message: preImage, privateKey: privateKey)
        let image = try! txBuilder.buildForSend(amount: amount, destination: destination, meta: meta, signature: signature)
        
        let expectedPreImage = Data(hexString: "05007120f76076bcb0efdf94c7219e116899d0163ea61cb428183d71324eb33b2bce0300943577a5030c001a0000000500000091b171bb158e2d3848fa23a9f1c25182fb8e20313b2c1eb49219da7a70ce90c35d2143bb808626d63ad7e1cda70fa8697059d670a992e82cd440fbb95ea40351")
        let expectedImage = Data(hexString: "3502849dca538b7a925b8ea979cc546464a3c5f81d2398a3a272f6f93bdf4803f2f7830073e59cef381aedf56d7af076bafff9857ffc1e3bd7d1d7484176ff5b58b73f1211a518e1ed1fd2ea201bd31869c0798bba4ffe753998c409d098b65d25dff801a5030c0005007120f76076bcb0efdf94c7219e116899d0163ea61cb428183d71324eb33b2bce0300943577")
        
        XCTAssertEqual(preImage, expectedPreImage)
        
        
        let (imageWithoutSignature, expectedImageWithoutSignature) = removeSignature(image: image, expectedImage: expectedImage, signature: signature)
        XCTAssertEqual(imageWithoutSignature, expectedImageWithoutSignature)
    }
    
    func testTransaction() {
        let toAddress = Data(hexString: "0x8eaf04151687736326c9fea17e25fc5287613693c912909cb226aa4794f26a48")
        
        let privateKey = Data(hexString: "0xabf8e5bdbe30c65656c0a3cbd181ff8a56294a69dfedd27982aace4a76909115")
        let publicKey = try! Curve25519.Signing.PrivateKey(rawRepresentation: privateKey).publicKey.rawRepresentation
        let blockchain: Blockchain = .polkadot(testnet: false)
        let network: PolkadotNetwork = .init(blockchain: blockchain)!
        
        let txBuilder = PolkadotTransactionBuilder(blockchain: blockchain, walletPublicKey: publicKey, network: network)
        
        let amount = Amount(with: blockchain, value: 12345 / blockchain.decimalValue)
        let destination = try! PolkadotAddressService(network: network).makeAddress(from: toAddress)
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
        
        let expectedPreImage = Data(hexString: "05008eaf04151687736326c9fea17e25fc5287613693c912909cb226aa4794f26a48e5c032000000110000000300000091b171bb158e2d3848fa23a9f1c25182fb8e20313b2c1eb49219da7a70ce90c3343a3f4258fd92f5ca6ca5abdf473d86a78b0bcd0dc09c568ca594245cc8c642")
        let expectedImage = Data(hexString: "29028488dc3417d5058ec4b4503e0c12ea1a0a89be200fe98922423d4334014fa6b0ee003d91a06263956d8ce3ce5c55455baefff299d9cb2bb3f76866b6828ee4083770b6c03b05d7b6eb510ac78d047002c1fe5c6ee4b37c9c5a8b09ea07677f12e50d3200000005008eaf04151687736326c9fea17e25fc5287613693c912909cb226aa4794f26a48e5c0")
        
        XCTAssertEqual(preImage, expectedPreImage)
        
        
        let (imageWithoutSignature, expectedImageWithoutSignature) = removeSignature(image: image, expectedImage: expectedImage, signature: signature)
        XCTAssertEqual(imageWithoutSignature, expectedImageWithoutSignature)
    }
    
    func testTransaction72dd5b() {
        let privateKey = Data(hexString: "37932b086586a6675e66e562fe68bd3eeea4177d066619c602fe3efc290ada62")
        let publicKey = try! Curve25519.Signing.PrivateKey(rawRepresentation: privateKey).publicKey.rawRepresentation
        let blockchain: Blockchain = .polkadot(testnet: false)
        let network: PolkadotNetwork = .init(blockchain: blockchain)!
        
        let txBuilder = PolkadotTransactionBuilder(blockchain: blockchain, walletPublicKey: publicKey, network: network)
        
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
        sizeTester.testTxSize(preImage)
        
        let signature = try! signEd25519(message: preImage, privateKey: privateKey)
        let image = try! txBuilder.buildForSend(amount: amount, destination: destination, meta: meta, signature: signature)
        
        let expectedPreImage = Data(hexString: "0500007120f76076bcb0efdf94c7219e116899d0163ea61cb428183d71324eb33b2bce0700e40b5402050104001c0000000600000091b171bb158e2d3848fa23a9f1c25182fb8e20313b2c1eb49219da7a70ce90c37d5fa17b70251d0806f26156b1b698dfd09e040642fa092595ce0a78e9e84fcd")
        let expectedImage = Data(hexString: "410284008d96660f14babe708b5e61853c9f5929bc90dd9874485bf4d6dc32d3e6f22eaa0038ec4973ab9773dfcbf170b8d27d36d89b85c3145e038d68914de83cf1f7aca24af64c55ec51ba9f45c5a4d74a9917dee380e9171108921c3e5546e05be15206050104000500007120f76076bcb0efdf94c7219e116899d0163ea61cb428183d71324eb33b2bce0700e40b5402")
        
        XCTAssertEqual(preImage, expectedPreImage)
        
        
        let (imageWithoutSignature, expectedImageWithoutSignature) = removeSignature(image: image, expectedImage: expectedImage, signature: signature)
        XCTAssertEqual(imageWithoutSignature, expectedImageWithoutSignature)
    }
    
    func testAzeroTransaction() {
        let toAddress = Data(hexString: "0x8eaf04151687736326c9fea17e25fc5287613693c912909cb226aa4794f26a48")
        
        let privateKey = Data(hexString: "0xabf8e5bdbe30c65656c0a3cbd181ff8a56294a69dfedd27982aace4a76909115")
        let publicKey = try! Curve25519.Signing.PrivateKey(rawRepresentation: privateKey).publicKey.rawRepresentation
        let blockchain: Blockchain = .azero(testnet: false)
        let network: PolkadotNetwork = .init(blockchain: blockchain)!
        
        let txBuilder = PolkadotTransactionBuilder(blockchain: blockchain, walletPublicKey: publicKey, network: network)
        
        let amount = Amount(with: blockchain, value: 12345 / blockchain.decimalValue)
        let destination = try! PolkadotAddressService(network: network).makeAddress(from: toAddress)
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
