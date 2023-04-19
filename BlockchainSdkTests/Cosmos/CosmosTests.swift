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
}
