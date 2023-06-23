//
//  CardanoTests.swift
//  BlockchainSdkTests
//
//  Created by Sergey Balashov on 15.06.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import XCTest
import WalletCore

@testable import BlockchainSdk

class CardanoTests: XCTestCase {
    var transactionBuilder: CardanoTransactionBuilder!

    var walletCorePrivateKey: PrivateKey {
        PrivateKey(
            data: Data(hex: "089b68e458861be0c44bf9f7967f05cc91e51ede86dc679448a3566990b7785bd48c330875b1e0d03caaed0e67cecc42075dce1c7a13b1c49240508848ac82f603391c68824881ae3fc23a56a1a75ada3b96382db502e37564e84a5413cfaf1290dbd508e5ec71afaea98da2df1533c22ef02a26bb87b31907d0b2738fb7785b38d53aa68fc01230784c9209b2b2a2faf28491b3b1f1d221e63e704bbd0403c4154425dfbb01a2c5c042da411703603f89af89e57faae2946e2a5c18b1c5ca0e")
        )!
    }

    var walletCorePublicKey: PublicKey {
        walletCorePrivateKey.getPublicKey(coinType: coinType)
    }

    // addr1vyn6tvyc3daxl8wwvm2glay287dfa7xjgdm2jdl308ksy9canqafn
    var walletCoreAddress: AnyAddress {
        AnyAddress(
            string: "addr1qxxe304qg9py8hyyqu8evfj4wln7dnms943wsugpdzzsxnkvvjljtzuwxvx0pnwelkcruy95ujkq3aw6rl0vvg32x35qc92xkq",
            coin: coinType
        )!
    }

    let blockchain = Blockchain.cardano(shelley: true)
    let coinType = CoinType.cardano

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        transactionBuilder = CardanoTransactionBuilder()
    }
    
    // We use compress publicKey in Tangem
    func test_compress_address() throws {
        // given
        let tangemPublicKey = Data(hex: "35E60B25785480A2105F378945DEF8048009212825A8685406C47D3901B836AB")
        let tangemAddress = "addr1v9jlkv7lv2m4zxqyljd2jjajw8n27v6gjpuznya09zavu7c5r9mxs"
        
        // when
        let publicKey = try XCTUnwrap(PublicKey(data: tangemPublicKey, type: coinType.publicKeyType))
        let address = AnyAddress(publicKey: publicKey, coin: coinType)
        
        // then
        XCTAssertEqual(address.description, tangemAddress)
    }
    
    func test_walletCore_publicKeyFromPrivate() {
        XCTAssertEqual(walletCorePublicKey.data.hex, "fafa7eb4146220db67156a03a5f7a79c666df83eb31abbfbe77c85e06d40da3110f3245ddf9132ecef98c670272ef39c03a232107733d4a1d28cb53318df26faf4b8d5201961e68f2e177ba594101f513ee70fe70a41324e8ea8eb787ffda6f4bf2eea84515a4e16c4ff06c92381822d910b5cbf9e9c144e1fb76a6291af7276")
    }

    func test_address() {
        // when
        let address = AnyAddress(publicKey: walletCorePublicKey, coin: coinType)
        
        // then
        XCTAssertEqual(address.description, walletCoreAddress.description)
    }
    
    func testSignTransfer() throws {
        let transaction = Transaction(
            amount: Amount(with: blockchain, value: 7000000),
            fee: .zero(for: blockchain),
            sourceAddress: walletCoreAddress.description,
            destinationAddress: "addr1q92cmkgzv9h4e5q7mnrzsuxtgayvg4qr7y3gyx97ukmz3dfx7r9fu73vqn25377ke6r0xk97zw07dqr9y5myxlgadl2s0dgke5",
            changeAddress: walletCoreAddress.description
        )
        
        let utxos = [
            CardanoUnspentOutput(address: walletCoreAddress.description,
                                 amount: 1500000,
                                 outputIndex: 1,
                                 transactionHash: "f074134aabbfb13b8aec7cf5465b1e5a862bde5cb88532cc7e64619179b3e767"),
            CardanoUnspentOutput(address: walletCoreAddress.description,
                                 amount: 6500000,
                                 outputIndex: 0,
                                 transactionHash: "554f2fd942a23d06835d26bbd78f0106fa94c8a551114a0bef81927f66467af0"),
        ]
        
        transactionBuilder.update(timeToLife: 53333333)
        transactionBuilder.update(outputs: utxos)
        let dataForSign = try transactionBuilder.buildForSign(transaction: transaction)
        
        // Sign
        let signature = try XCTUnwrap(walletCorePrivateKey.sign(digest: dataForSign, curve: coinType.curve))
        XCTAssertEqual(
            signature.hexString,
            "7cf591599852b5f5e007fdc241062405c47e519266c0d884b0767c1d4f5eacce00db035998e53ed10ca4ba5ce4aac8693798089717ce6cf4415f345cc764200e"
        )
        
        let signatureInfo = SignatureInfo(signature: signature, publicKey: walletCorePublicKey.data)
        let encoded = try transactionBuilder.buildForSend(transaction: transaction, signature: signatureInfo)
        XCTAssertEqual(
            encoded.hexString,
            "83a40082825820554f2fd942a23d06835d26bbd78f0106fa94c8a551114a0bef81927f66467af000825820f074134aabbfb13b8aec7cf5465b1e5a862bde5cb88532cc7e64619179b3e76701018282583901558dd902616f5cd01edcc62870cb4748c45403f1228218bee5b628b526f0ca9e7a2c04d548fbd6ce86f358be139fe680652536437d1d6fd51a006acfc082583901df58ee97ce7a46cd8bdeec4e5f3a03297eb197825ed5681191110804df22424b6880b39e4bac8c58de9fe6d23d79aaf44756389d827aa09b1a000ca96c021a000298d4031a032dcd55a100818258206d8a0b425bd2ec9692af39b1c0cf0e51caa07a603550e22f54091e872c7df29058407cf591599852b5f5e007fdc241062405c47e519266c0d884b0767c1d4f5eacce00db035998e53ed10ca4ba5ce4aac8693798089717ce6cf4415f345cc764200ef6"
        )
    }
}

/*
 {
    "Right":[
       {
          "tag":"CUtxo",
          "cuOutIndex":1,
          "cuAddress":"addr1qx55ymlqemndq8gluv40v58pu76a2tp4mzjnyx8n6zrp2vtzrs43a0057y0edkn8lh9su8vh5lnhs4npv6l9tuvncv8swc7t08",
          "cuId":"cde74834c41bfd276b860fa7c33a5a0503385f3b4eb6556ab0738c0e6e35cf96",
          "cuCoins":{
             "getCoin":"5316591",
             "getTokens":[

             ]
          }
       },
       {
          "tag":"CUtxo",
          "cuOutIndex":2,
          "cuAddress":"addr1qx55ymlqemndq8gluv40v58pu76a2tp4mzjnyx8n6zrp2vtzrs43a0057y0edkn8lh9su8vh5lnhs4npv6l9tuvncv8swc7t08",
          "cuId":"4c0bd7424e4940119c59d26e61adaa35caa6655a3ee3d86aa5f261bf1482fe12",
          "cuCoins":{
             "getCoin":"2000000",
             "getTokens":[
                {
                   "policyId":"9a9693a9a37912a5097918f97918d15240c92ab729a0b7c4aa144d77",
                   "assetName":"53554e444145",
                   "quantity":"25877662"
                }
             ]
          }
       }
    ]
 }
 */
