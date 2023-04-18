//
//  CosmosTests.swift
//  BlockchainSdkTests
//
//  Created by Andrey Chukavin on 10.04.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import XCTest
//import TangemSdk
//import class WalletCore.PrivateKey
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
            gas: 200_000
        )
        
        let signer = PrivateKeySigner(privateKey: privateKey, coin: cosmosChain.coin)
        let transactionData = try txBuilder.buildForSend(input: input, signer: signer)
        let transactionString = String(data: transactionData, encoding: .utf8)!
        
        let expectedOutput = "{\"tx_bytes\": \"CowBCokBChwvY29zbW9zLmJhbmsudjFiZXRhMS5Nc2dTZW5kEmkKLWNvc21vczFoc2s2anJ5eXFqZmhwNWRoYzU1dGM5anRja3lneDBlcGg2ZGQwMhItY29zbW9zMXp0NTBhenVwYW5xbGZhbTVhZmh2M2hleHd5dXRudWtlaDRjNTczGgkKBG11b24SATESZQpQCkYKHy9jb3Ntb3MuY3J5cHRvLnNlY3AyNTZrMS5QdWJLZXkSIwohAlcobsPzfTNVe7uqAAsndErJAjqplnyudaGB0f+R+p3FEgQKAggBGAgSEQoLCgRtdW9uEgMyMDAQwJoMGkD54fQAFlekIAnE62hZYl0uQelh/HLv0oQpCciY5Dn8H1SZFuTsrGdu41PH1Uxa4woptCELi/8Ov9yzdeEFAC9H\", \"mode\": \"BROADCAST_MODE_BLOCK\"}"
        XCTAssertJSONEqual(transactionString, expectedOutput)
    }
    
    func testDecodingNetworkModels() {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        let accountResponse = #"{"account":{"@type":"/cosmos.auth.v1beta1.BaseAccount","address":"cosmos15cmkwr223aymmjtvgvpuv37vr83zeua2sxqtat","pub_key":{"@type":"/cosmos.crypto.secp256k1.PubKey","key":"Awjv+yiteafCIp2X0C2QLoJCFTg8K7voJGfQxeRw6tNo"},"account_number":"725072","sequence":"2"}}"#
        XCTAssertNoThrow(try decoder.decode(CosmosAccountResponse.self, from: accountResponse.data(using: .utf8)!))
        
        let balanceResponse = #"{"balances":[{"denom":"uatom","amount":"3998996"}],"pagination":{"next_key":null,"total":"1"}}"#
        XCTAssertNoThrow(try decoder.decode(CosmosBalanceResponse.self, from: balanceResponse.data(using: .utf8)!))
        
        let simulateResponse = #"{"gas_info":{"gas_wanted":"0","gas_used":"78107"},"result":{"data":"Ch4KHC9jb3Ntb3MuYmFuay52MWJldGExLk1zZ1NlbmQ=","log":"[{\"events\":[{\"type\":\"coin_received\",\"attributes\":[{\"key\":\"receiver\",\"value\":\"cosmos15aptdqmm7ddgtcrjvc5hs988rlrkze40l4q0he\"},{\"key\":\"amount\",\"value\":\"1uatom\"}]},{\"type\":\"coin_spent\",\"attributes\":[{\"key\":\"spender\",\"value\":\"cosmos15cmkwr223aymmjtvgvpuv37vr83zeua2sxqtat\"},{\"key\":\"amount\",\"value\":\"1uatom\"}]},{\"type\":\"message\",\"attributes\":[{\"key\":\"action\",\"value\":\"/cosmos.bank.v1beta1.MsgSend\"},{\"key\":\"sender\",\"value\":\"cosmos15cmkwr223aymmjtvgvpuv37vr83zeua2sxqtat\"},{\"key\":\"module\",\"value\":\"bank\"}]},{\"type\":\"transfer\",\"attributes\":[{\"key\":\"recipient\",\"value\":\"cosmos15aptdqmm7ddgtcrjvc5hs988rlrkze40l4q0he\"},{\"key\":\"sender\",\"value\":\"cosmos15cmkwr223aymmjtvgvpuv37vr83zeua2sxqtat\"},{\"key\":\"amount\",\"value\":\"1uatom\"}]}]}]","events":[{"type":"message","attributes":[{"key":"YWN0aW9u","value":"L2Nvc21vcy5iYW5rLnYxYmV0YTEuTXNnU2VuZA==","index":false}]},{"type":"coin_spent","attributes":[{"key":"c3BlbmRlcg==","value":"Y29zbW9zMTVjbWt3cjIyM2F5bW1qdHZndnB1djM3dnI4M3pldWEyc3hxdGF0","index":false},{"key":"YW1vdW50","value":"MXVhdG9t","index":false}]},{"type":"coin_received","attributes":[{"key":"cmVjZWl2ZXI=","value":"Y29zbW9zMTVhcHRkcW1tN2RkZ3Rjcmp2YzVoczk4OHJscmt6ZTQwbDRxMGhl","index":false},{"key":"YW1vdW50","value":"MXVhdG9t","index":false}]},{"type":"transfer","attributes":[{"key":"cmVjaXBpZW50","value":"Y29zbW9zMTVhcHRkcW1tN2RkZ3Rjcmp2YzVoczk4OHJscmt6ZTQwbDRxMGhl","index":false},{"key":"c2VuZGVy","value":"Y29zbW9zMTVjbWt3cjIyM2F5bW1qdHZndnB1djM3dnI4M3pldWEyc3hxdGF0","index":false},{"key":"YW1vdW50","value":"MXVhdG9t","index":false}]},{"type":"message","attributes":[{"key":"c2VuZGVy","value":"Y29zbW9zMTVjbWt3cjIyM2F5bW1qdHZndnB1djM3dnI4M3pldWEyc3hxdGF0","index":false}]},{"type":"message","attributes":[{"key":"bW9kdWxl","value":"YmFuaw==","index":false}]}]}}"#
        XCTAssertNoThrow(try decoder.decode(CosmosSimulateResponse.self, from: simulateResponse.data(using: .utf8)!))

        let txResponse = #"{"tx_response":{"height":"15423947","txhash":"FE0034D60EB51ECCCFE5459B93AAD51370CE875DE9CC665184D01290AE256A37","codespace":"","code":0,"data":"0A1E0A1C2F636F736D6F732E62616E6B2E763162657461312E4D736753656E64","raw_log":"[{\"events\":[{\"type\":\"coin_received\",\"attributes\":[{\"key\":\"receiver\",\"value\":\"cosmos15aptdqmm7ddgtcrjvc5hs988rlrkze40l4q0he\"},{\"key\":\"amount\",\"value\":\"1uatom\"}]},{\"type\":\"coin_spent\",\"attributes\":[{\"key\":\"spender\",\"value\":\"cosmos15cmkwr223aymmjtvgvpuv37vr83zeua2sxqtat\"},{\"key\":\"amount\",\"value\":\"1uatom\"}]},{\"type\":\"message\",\"attributes\":[{\"key\":\"action\",\"value\":\"/cosmos.bank.v1beta1.MsgSend\"},{\"key\":\"sender\",\"value\":\"cosmos15cmkwr223aymmjtvgvpuv37vr83zeua2sxqtat\"},{\"key\":\"module\",\"value\":\"bank\"}]},{\"type\":\"transfer\",\"attributes\":[{\"key\":\"recipient\",\"value\":\"cosmos15aptdqmm7ddgtcrjvc5hs988rlrkze40l4q0he\"},{\"key\":\"sender\",\"value\":\"cosmos15cmkwr223aymmjtvgvpuv37vr83zeua2sxqtat\"},{\"key\":\"amount\",\"value\":\"1uatom\"}]}]}]","logs":[{"msg_index":0,"log":"","events":[{"type":"coin_received","attributes":[{"key":"receiver","value":"cosmos15aptdqmm7ddgtcrjvc5hs988rlrkze40l4q0he"},{"key":"amount","value":"1uatom"}]},{"type":"coin_spent","attributes":[{"key":"spender","value":"cosmos15cmkwr223aymmjtvgvpuv37vr83zeua2sxqtat"},{"key":"amount","value":"1uatom"}]},{"type":"message","attributes":[{"key":"action","value":"/cosmos.bank.v1beta1.MsgSend"},{"key":"sender","value":"cosmos15cmkwr223aymmjtvgvpuv37vr83zeua2sxqtat"},{"key":"module","value":"bank"}]},{"type":"transfer","attributes":[{"key":"recipient","value":"cosmos15aptdqmm7ddgtcrjvc5hs988rlrkze40l4q0he"},{"key":"sender","value":"cosmos15cmkwr223aymmjtvgvpuv37vr83zeua2sxqtat"},{"key":"amount","value":"1uatom"}]}]}],"info":"","gas_wanted":"200002","gas_used":"71513","tx":null,"timestamp":"","events":[{"type":"coin_spent","attributes":[{"key":"c3BlbmRlcg==","value":"Y29zbW9zMTVjbWt3cjIyM2F5bW1qdHZndnB1djM3dnI4M3pldWEyc3hxdGF0","index":true},{"key":"YW1vdW50","value":"NTAxdWF0b20=","index":true}]},{"type":"coin_received","attributes":[{"key":"cmVjZWl2ZXI=","value":"Y29zbW9zMTd4cGZ2YWttMmFtZzk2MnlsczZmODR6M2tlbGw4YzVsc2VycXRh","index":true},{"key":"YW1vdW50","value":"NTAxdWF0b20=","index":true}]},{"type":"transfer","attributes":[{"key":"cmVjaXBpZW50","value":"Y29zbW9zMTd4cGZ2YWttMmFtZzk2MnlsczZmODR6M2tlbGw4YzVsc2VycXRh","index":true},{"key":"c2VuZGVy","value":"Y29zbW9zMTVjbWt3cjIyM2F5bW1qdHZndnB1djM3dnI4M3pldWEyc3hxdGF0","index":true},{"key":"YW1vdW50","value":"NTAxdWF0b20=","index":true}]},{"type":"message","attributes":[{"key":"c2VuZGVy","value":"Y29zbW9zMTVjbWt3cjIyM2F5bW1qdHZndnB1djM3dnI4M3pldWEyc3hxdGF0","index":true}]},{"type":"tx","attributes":[{"key":"ZmVl","value":"NTAxdWF0b20=","index":true},{"key":"ZmVlX3BheWVy","value":"Y29zbW9zMTVjbWt3cjIyM2F5bW1qdHZndnB1djM3dnI4M3pldWEyc3hxdGF0","index":true}]},{"type":"tx","attributes":[{"key":"YWNjX3NlcQ==","value":"Y29zbW9zMTVjbWt3cjIyM2F5bW1qdHZndnB1djM3dnI4M3pldWEyc3hxdGF0LzE=","index":true}]},{"type":"tx","attributes":[{"key":"c2lnbmF0dXJl","value":"WEE5ZlY2OEFLU3E1MVNVTmxPVWVQQytteTdyTXRIVkFGQ1NjM2NQeWRTSkJydHZVRnFBQjRJVkpFd2FLVFRJOWNLd2drL2FnQ3pKaDNWVkUzc2tRRlE9PQ==","index":true}]},{"type":"message","attributes":[{"key":"YWN0aW9u","value":"L2Nvc21vcy5iYW5rLnYxYmV0YTEuTXNnU2VuZA==","index":true}]},{"type":"coin_spent","attributes":[{"key":"c3BlbmRlcg==","value":"Y29zbW9zMTVjbWt3cjIyM2F5bW1qdHZndnB1djM3dnI4M3pldWEyc3hxdGF0","index":true},{"key":"YW1vdW50","value":"MXVhdG9t","index":true}]},{"type":"coin_received","attributes":[{"key":"cmVjZWl2ZXI=","value":"Y29zbW9zMTVhcHRkcW1tN2RkZ3Rjcmp2YzVoczk4OHJscmt6ZTQwbDRxMGhl","index":true},{"key":"YW1vdW50","value":"MXVhdG9t","index":true}]},{"type":"transfer","attributes":[{"key":"cmVjaXBpZW50","value":"Y29zbW9zMTVhcHRkcW1tN2RkZ3Rjcmp2YzVoczk4OHJscmt6ZTQwbDRxMGhl","index":true},{"key":"c2VuZGVy","value":"Y29zbW9zMTVjbWt3cjIyM2F5bW1qdHZndnB1djM3dnI4M3pldWEyc3hxdGF0","index":true},{"key":"YW1vdW50","value":"MXVhdG9t","index":true}]},{"type":"message","attributes":[{"key":"c2VuZGVy","value":"Y29zbW9zMTVjbWt3cjIyM2F5bW1qdHZndnB1djM3dnI4M3pldWEyc3hxdGF0","index":true}]},{"type":"message","attributes":[{"key":"bW9kdWxl","value":"YmFuaw==","index":true}]}]}}"#
        XCTAssertNoThrow(try decoder.decode(CosmosTxResponse.self, from: txResponse.data(using: .utf8)!))
    }
}
