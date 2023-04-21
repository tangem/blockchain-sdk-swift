//
//  CosmosTests.swift
//  BlockchainSdkTests
//
//  Created by Andrey Chukavin on 10.04.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import XCTest
import WalletCore

@testable import BlockchainSdk

class CosmosTests: XCTestCase {
    // From TrustWallet
    func testTransaction() throws {
        let cosmosChain = CosmosChain.gaia
        
        let privateKey = PrivateKey(data: Data(hexString: "80e81ea269e66a0a05b11236df7919fb7fbeedba87452d667489d7403a02f005"))!
        let publicKeyData = privateKey.getPublicKeySecp256k1(compressed: true).data
        
        let addresses = try cosmosChain.blockchain.getAddressService().makeAddresses(from: publicKeyData)
        
        let publicKey: BlockchainSdk.Wallet.PublicKey! = .init(seedKey: publicKeyData, derivedKey: nil, derivationPath: nil)
        let wallet = Wallet(blockchain: cosmosChain.blockchain, addresses: addresses, publicKey: publicKey)
        
        let txBuilder = CosmosTransactionBuilder(wallet: wallet, cosmosChain: cosmosChain)
        txBuilder.setAccountNumber(1037)
        txBuilder.setSequenceNumber(8)
        
        let input = try! txBuilder.buildForSign(
            amount: Amount(with: cosmosChain.blockchain, value: 0.000001),
            source: wallet.address,
            destination: "cosmos1zt50azupanqlfam5afhv3hexwyutnukeh4c573",
            feeAmount: 0.000200,
            gas: 200_000,
            params: nil
        )
        
        let signer = PrivateKeySigner(privateKey: privateKey, coin: cosmosChain.coin)
        let transactionData = try txBuilder.buildForSend(input: input, signer: signer)
        let transactionString = String(data: transactionData, encoding: .utf8)!
        
        let expectedOutput = "{\"tx_bytes\": \"CowBCokBChwvY29zbW9zLmJhbmsudjFiZXRhMS5Nc2dTZW5kEmkKLWNvc21vczFoc2s2anJ5eXFqZmhwNWRoYzU1dGM5anRja3lneDBlcGg2ZGQwMhItY29zbW9zMXp0NTBhenVwYW5xbGZhbTVhZmh2M2hleHd5dXRudWtlaDRjNTczGgkKBG11b24SATESZQpQCkYKHy9jb3Ntb3MuY3J5cHRvLnNlY3AyNTZrMS5QdWJLZXkSIwohAlcobsPzfTNVe7uqAAsndErJAjqplnyudaGB0f+R+p3FEgQKAggBGAgSEQoLCgRtdW9uEgMyMDAQwJoMGkD54fQAFlekIAnE62hZYl0uQelh/HLv0oQpCciY5Dn8H1SZFuTsrGdu41PH1Uxa4woptCELi/8Ov9yzdeEFAC9H\", \"mode\": \"BROADCAST_MODE_BLOCK\"}"
        XCTAssertJSONEqual(transactionString, expectedOutput)
    }
    
    func testTerraV1Transaction() throws {
        let cosmosChain = CosmosChain.terraV1
        
        let privateKey = PrivateKey(data: Data(hexString: "1037f828ca313f4c9e120316e8e9ff25e17f07fe66ba557d5bc5e2eeb7cba8f6"))!
        let publicKeyData = privateKey.getPublicKeySecp256k1(compressed: true).data
        
        let addresses = try cosmosChain.blockchain.getAddressService().makeAddresses(from: publicKeyData)
        
        let publicKey: BlockchainSdk.Wallet.PublicKey! = .init(seedKey: publicKeyData, derivedKey: nil, derivationPath: nil)
        let wallet = Wallet(blockchain: cosmosChain.blockchain, addresses: addresses, publicKey: publicKey)
        
        let txBuilder = CosmosTransactionBuilder(wallet: wallet, cosmosChain: cosmosChain)
        txBuilder.setAccountNumber(158)
        txBuilder.setSequenceNumber(0)
        
        let input = try! txBuilder.buildForSign(
            amount: Amount(with: cosmosChain.blockchain, value: 1),
            source: wallet.address,
            destination: "terra1hdp298kaz0eezpgl6scsykxljrje3667d233ms",
            feeAmount: 0.003,
            gas: 200_000,
            params: nil
        )
        
        let signer = PrivateKeySigner(privateKey: privateKey, coin: cosmosChain.coin)
        let transactionData = try txBuilder.buildForSend(input: input, signer: signer)
        let transactionString = String(data: transactionData, encoding: .utf8)!
        
        let expectedOutput =
            """
            {"mode":"BROADCAST_MODE_BLOCK","tx_bytes":"CpEBCo4BChwvY29zbW9zLmJhbmsudjFiZXRhMS5Nc2dTZW5kEm4KLHRlcnJhMWpmOWFhajlteXJ6c25tcGRyN3R3ZWNuYWZ0em1rdTJtaHMyaGZlEix0ZXJyYTFoZHAyOThrYXowZWV6cGdsNnNjc3lreGxqcmplMzY2N2QyMzNtcxoQCgV1bHVuYRIHMTAwMDAwMBJlCk4KRgofL2Nvc21vcy5jcnlwdG8uc2VjcDI1NmsxLlB1YktleRIjCiEDXfGFVmUh1qeAIxnuBuGijpe3dy37X90Tym8FdVGJaOQSBAoCCAESEwoNCgV1bHVuYRIEMzAwMBDAmgwaQLDY3SS1u9SkOPbYLkZ85NmE2pjozYZS9HUBLmMTRJExalSLFYlXYjaxgbzCGUWYSQe/7rijDDngiDGEqLZAmIU="}
        """
        
        XCTAssertJSONEqual(transactionString, expectedOutput)
    }
    
    func testTerraV1USDTransaction() throws {
        let cosmosChain = CosmosChain.terraV1USD
        
        let privateKey = PrivateKey(data: Data(hexString: "80e81ea269e66a0a05b11236df7919fb7fbeedba87452d667489d7403a02f005"))!
        let publicKeyData = privateKey.getPublicKeySecp256k1(compressed: true).data
        
        let addresses = try cosmosChain.blockchain.getAddressService().makeAddresses(from: publicKeyData)
        
        let publicKey: BlockchainSdk.Wallet.PublicKey! = .init(seedKey: publicKeyData, derivedKey: nil, derivationPath: nil)
        let wallet = Wallet(blockchain: cosmosChain.blockchain, addresses: addresses, publicKey: publicKey)
        
        let txBuilder = CosmosTransactionBuilder(wallet: wallet, cosmosChain: cosmosChain)
        txBuilder.setAccountNumber(1037)
        txBuilder.setSequenceNumber(1)
        
        let input = try! txBuilder.buildForSign(
            amount: Amount(with: cosmosChain.blockchain, value: 1),
            source: wallet.address,
            destination: "terra1jlgaqy9nvn2hf5t2sra9ycz8s77wnf9l0kmgcp",
            feeAmount: 0.03,
            gas: 200_000,
            params: nil
        )
        
        let signer = PrivateKeySigner(privateKey: privateKey, coin: cosmosChain.coin)
        let transactionData = try txBuilder.buildForSend(input: input, signer: signer)
        let transactionString = String(data: transactionData, encoding: .utf8)!
        
        let expectedOutput =
                """
                {"mode":"BROADCAST_MODE_BLOCK","tx_bytes":"CpABCo0BChwvY29zbW9zLmJhbmsudjFiZXRhMS5Nc2dTZW5kEm0KLHRlcnJhMWhzazZqcnl5cWpmaHA1ZGhjNTV0YzlqdGNreWd4MGVwMzdoZGQyEix0ZXJyYTFqbGdhcXk5bnZuMmhmNXQyc3JhOXljejhzNzd3bmY5bDBrbWdjcBoPCgR1dXNkEgcxMDAwMDAwEnUKUApGCh8vY29zbW9zLmNyeXB0by5zZWNwMjU2azEuUHViS2V5EiMKIQJXKG7D830zVXu7qgALJ3RKyQI6qZZ8rnWhgdH/kfqdxRIECgIIARgBEiEKDQoEdXVzZBIFMzIwMDAKDAoEdXVzZBIEMjAwMBDAmgwaQKIIynXT/E5IzSV33NJcfeFzEuh4R516h1nJq+UGeh0CHIBqVE0gSvw081YhYSoEaRFZi+emer6Qd1lk0eHu8vQ="}
                """
        
        XCTAssertJSONEqual(transactionString, expectedOutput)
    }
    
    
    // From TrustWallet
    func testTerraV2Transaction() throws {
        let cosmosChain = CosmosChain.terraV2
        
        let privateKey = PrivateKey(data: Data(hexString: "80e81ea269e66a0a05b11236df7919fb7fbeedba87452d667489d7403a02f005"))!
        let publicKeyData = privateKey.getPublicKeySecp256k1(compressed: true).data
        
        let addresses = try cosmosChain.blockchain.getAddressService().makeAddresses(from: publicKeyData)
        
        let publicKey: BlockchainSdk.Wallet.PublicKey! = .init(seedKey: publicKeyData, derivedKey: nil, derivationPath: nil)
        let wallet = Wallet(blockchain: cosmosChain.blockchain, addresses: addresses, publicKey: publicKey)
        
        let txBuilder = CosmosTransactionBuilder(wallet: wallet, cosmosChain: cosmosChain)
        txBuilder.setAccountNumber(1037)
        txBuilder.setSequenceNumber(1)
        
        let input = try! txBuilder.buildForSign(
            amount: Amount(with: cosmosChain.blockchain, value: 1),
            source: wallet.address,
            destination: "terra1jlgaqy9nvn2hf5t2sra9ycz8s77wnf9l0kmgcp",
            feeAmount: 0.03,
            gas: 200_000,
            params: nil
        )
        
        let signer = PrivateKeySigner(privateKey: privateKey, coin: cosmosChain.coin)
        let transactionData = try txBuilder.buildForSend(input: input, signer: signer)
        let transactionString = String(data: transactionData, encoding: .utf8)!
        
        let expectedOutput =
                """
                {
                    "tx_bytes": "CpEBCo4BChwvY29zbW9zLmJhbmsudjFiZXRhMS5Nc2dTZW5kEm4KLHRlcnJhMWhzazZqcnl5cWpmaHA1ZGhjNTV0YzlqdGNreWd4MGVwMzdoZGQyEix0ZXJyYTFqbGdhcXk5bnZuMmhmNXQyc3JhOXljejhzNzd3bmY5bDBrbWdjcBoQCgV1bHVuYRIHMTAwMDAwMBJoClAKRgofL2Nvc21vcy5jcnlwdG8uc2VjcDI1NmsxLlB1YktleRIjCiECVyhuw/N9M1V7u6oACyd0SskCOqmWfK51oYHR/5H6ncUSBAoCCAEYARIUCg4KBXVsdW5hEgUzMDAwMBDAmgwaQPh0C3rjzdixIUiyPx3FlWAxzbKILNAcSRVeQnaTl1vsI5DEfYa2oYlUBLqyilcMCcU/iaJLhex30No2ak0Zn1Q=",
                    "mode": "BROADCAST_MODE_BLOCK"
                }
                """
        
        XCTAssertJSONEqual(transactionString, expectedOutput)
    }
}
