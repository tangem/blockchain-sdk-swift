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
            data: Data(hex: "98f266d1aac660179bc2f456033941238ee6b2beb8ed0f9f34c9902816781f5a9903d1d395d6ab887b65ea5e344ef09b449507c21a75f0ce8c59d0ed1c6764eba7f484aa383806735c46fd769c679ee41f8952952036a6e2338ada940b8a91f4e890ca4eb6bec44bf751b5a843174534af64d6ad1f44e0613db78a7018781f5aa151d2997f52059466b715d8eefab30a78b874ae6ef4931fa58bb21ef8ce2423d46f19d0fbf75afb0b9a24e31d533f4fd74cee3b56e162568e8defe37123afc4")
        )!
    }

    var walletCorePublicKey: PublicKey {
        walletCorePrivateKey.getPublicKeyEd25519Cardano()
    }

    var walletCoreAddress: AnyAddress {
        AnyAddress(
            string: "addr1q8043m5heeaydnvtmmkyuhe6qv5havvhsf0d26q3jygsspxlyfpyk6yqkw0yhtyvtr0flekj84u64az82cufmqn65zdsylzk23",
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
    
    func test_walletCore_publicKeyFromPrivate() {
        XCTAssertEqual(walletCorePublicKey.data.hex, "d163c8c4f0be7c22cd3a1152abb013c855ea614b92201497a568c5d93ceeb41ea7f484aa383806735c46fd769c679ee41f8952952036a6e2338ada940b8a91f40b5aaa6103dc10842894a1eeefc5447b9bcb9bcf227d77e57be195d17bc03263d46f19d0fbf75afb0b9a24e31d533f4fd74cee3b56e162568e8defe37123afc4")
    }
    
    func testSignTransfer() throws {
        let transaction = Transaction(
            amount: Amount(with: blockchain, value: 7),
            fee: .zero(for: blockchain),
            sourceAddress: walletCoreAddress.description,
            destinationAddress: "addr1q92cmkgzv9h4e5q7mnrzsuxtgayvg4qr7y3gyx97ukmz3dfx7r9fu73vqn25377ke6r0xk97zw07dqr9y5myxlgadl2s0dgke5",
            changeAddress: walletCoreAddress.description
        )
        
        let utxos = [
            CardanoUnspentOutput(address: walletCoreAddress.description,
                                 amount: 2500000,
                                 outputIndex: 1,
                                 transactionHash: "f074134aabbfb13b8aec7cf5465b1e5a862bde5cb88532cc7e64619179b3e767"),
            CardanoUnspentOutput(address: walletCoreAddress.description,
                                 amount: 6500000,
                                 outputIndex: 0,
                                 transactionHash: "554f2fd942a23d06835d26bbd78f0106fa94c8a551114a0bef81927f66467af0"),
        ]

        transactionBuilder.update(outputs: utxos)
        
        let dataForSign = try transactionBuilder.buildForSign(transaction: transaction)
        XCTAssertEqual(
            dataForSign.hex,
            "28eb61b607a881490facd20cc5adc865c8bc362d0c734866df725589373fcf61"
        )
        
        // Sign
        let signature = try XCTUnwrap(walletCorePrivateKey.sign(digest: dataForSign, curve: coinType.curve))
        XCTAssertEqual(
            signature.hex,
            "cc6ac55dda25e84cf2005542db6779fe7eec8d59bf541e3b5a39fd2f60d3113b592b620d7076c85f46989bf2b905338b25ffd839d77422d23c680a8bfd00590e"
        )
        
        let signatureInfo = SignatureInfo(signature: signature, publicKey: walletCorePublicKey.data)
        let encoded = try transactionBuilder.buildForSend(transaction: transaction, signature: signatureInfo)
        XCTAssertEqual(
            encoded.hex,
            "83a40082825820554f2fd942a23d06835d26bbd78f0106fa94c8a551114a0bef81927f66467af000825820f074134aabbfb13b8aec7cf5465b1e5a862bde5cb88532cc7e64619179b3e76701018282583901558dd902616f5cd01edcc62870cb4748c45403f1228218bee5b628b526f0ca9e7a2c04d548fbd6ce86f358be139fe680652536437d1d6fd51a006acfc082583901df58ee97ce7a46cd8bdeec4e5f3a03297eb197825ed5681191110804df22424b6880b39e4bac8c58de9fe6d23d79aaf44756389d827aa09b1a001bebac021a000298d4031a0b532b80a10081825820d163c8c4f0be7c22cd3a1152abb013c855ea614b92201497a568c5d93ceeb41e5840cc6ac55dda25e84cf2005542db6779fe7eec8d59bf541e3b5a39fd2f60d3113b592b620d7076c85f46989bf2b905338b25ffd839d77422d23c680a8bfd00590ef6"
        )
    }
    
    func testSignTransferFromLegacy() throws {
        let transaction = Transaction(
            amount: Amount(with: blockchain, value: 3),
            fee: .zero(for: blockchain),
            sourceAddress: "addr1vyn6tvyc3daxl8wwvm2glay287dfa7xjgdm2jdl308ksy9canqafn",
            destinationAddress: "addr1q90uh2eawrdc9vaemftgd50l28yrh9lqxtjjh4z6dnn0u7ggasexxdyyk9f05atygnjlccsjsggtc87hhqjna32fpv5qeq96ls",
            changeAddress: "addr1qx55ymlqemndq8gluv40v58pu76a2tp4mzjnyx8n6zrp2vtzrs43a0057y0edkn8lh9su8vh5lnhs4npv6l9tuvncv8swc7t08"
        )
        
        let utxos = [
            CardanoUnspentOutput(address: "Ae2tdPwUPEZ6vkqxSjJxaQYmDxHf5DTnxtZ67pFLJGTb9LTnCGkDP6ca3f8",
                                 amount: 2500000,
                                 outputIndex: 0,
                                 transactionHash: "8316e5007d61fb90652cabb41141972a38b5bc60954d602cf843476aa3f67f63"),
            CardanoUnspentOutput(address: "Ae2tdPwUPEZ6vkqxSjJxaQYmDxHf5DTnxtZ67pFLJGTb9LTnCGkDP6ca3f8",
                                 amount: 1700000,
                                 outputIndex: 1,
                                 transactionHash: "e29392c59c903fefb905730587d22cae8bda30bd8d9aeec3eca082ae77675946"),
        ]
        
        transactionBuilder.update(outputs: utxos)
        let dataForSign = try transactionBuilder.buildForSign(transaction: transaction)
        XCTAssertEqual(dataForSign.hex, "a783bea81724cbaf5f4595484b1894c76428b2b230ba582f50e80b993571526a")
        
        // Sign
        
        let signature = try XCTUnwrap(walletCorePrivateKey.sign(digest:dataForSign, curve: coinType.curve))
        let signatureInfo = SignatureInfo(signature: signature, publicKey: walletCorePublicKey.data)
        let encoded = try transactionBuilder.buildForSend(transaction: transaction, signature: signatureInfo)
        
        XCTAssertEqual(
            encoded.hex,
            "83a400828258208316e5007d61fb90652cabb41141972a38b5bc60954d602cf843476aa3f67f6300825820e29392c59c903fefb905730587d22cae8bda30bd8d9aeec3eca082ae77675946010182825839015fcbab3d70db82b3b9da5686d1ff51c83b97e032e52bd45a6ce6fe7908ec32633484b152fa756444e5fc62128210bc1fd7b8253ec5490b281a002dc6c082583901a9426fe0cee6d01d1fe32af650e1e7b5d52c35d8a53218f3d0861531621c2b1ebdf4f11f96da67fdcb0e1d97a7e778566166be55f193c30f1a000fee97021a000260e9031a0b532b80a10081825820d163c8c4f0be7c22cd3a1152abb013c855ea614b92201497a568c5d93ceeb41e5840424757355abfdec2cc140c1e42c99c83b6342cb28b7658f79b9b186705abec447a93c1cd3ae09517a93188fe51c8becc6bd0d2cf2f97beedec7d8cca6ca15100f6"
        )
    }
}
