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
        walletCorePrivateKey.getPublicKeyEd25519()
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
        XCTAssertEqual(walletCorePublicKey.data.hex, "399d7a953d7e907a5c6698e6b2c6b023fe659fa40f9874a74215889fcccbf825")
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
        let signature = try XCTUnwrap(walletCorePrivateKey.sign(digest: dataForSign, curve: .ed25519))
        XCTAssertEqual(
            signature.hex,
            "697a2c544e27d5db9daf031d838ba17c65e9597c9666b759ba28f1b3c8d1956ee2626b9a17afceb98f5fe0084ed01bcaf8dfc75c38255581a3544873e56d2604"
        )
        
        let signatureInfo = SignatureInfo(signature: signature, publicKey: walletCorePublicKey.data)
        let encoded = try transactionBuilder.buildForSend(transaction: transaction, signature: signatureInfo)
        XCTAssertEqual(
            encoded.hex,
            "83a40082825820554f2fd942a23d06835d26bbd78f0106fa94c8a551114a0bef81927f66467af000825820f074134aabbfb13b8aec7cf5465b1e5a862bde5cb88532cc7e64619179b3e76701018282583901558dd902616f5cd01edcc62870cb4748c45403f1228218bee5b628b526f0ca9e7a2c04d548fbd6ce86f358be139fe680652536437d1d6fd51a006acfc082583901df58ee97ce7a46cd8bdeec4e5f3a03297eb197825ed5681191110804df22424b6880b39e4bac8c58de9fe6d23d79aaf44756389d827aa09b1a001bebac021a000298d4031a0b532b80a10081825820399d7a953d7e907a5c6698e6b2c6b023fe659fa40f9874a74215889fcccbf8255840697a2c544e27d5db9daf031d838ba17c65e9597c9666b759ba28f1b3c8d1956ee2626b9a17afceb98f5fe0084ed01bcaf8dfc75c38255581a3544873e56d2604f6"
        )
    }
    
    func testSignTransferFromLegacy() throws {
        let transaction = Transaction(
            amount: Amount(with: blockchain, value: 1),
            fee: .zero(for: blockchain),
            sourceAddress: "addr1vyn6tvyc3daxl8wwvm2glay287dfa7xjgdm2jdl308ksy9canqafn",
            destinationAddress: "addr1q92cmkgzv9h4e5q7mnrzsuxtgayvg4qr7y3gyx97ukmz3dfx7r9fu73vqn25377ke6r0xk97zw07dqr9y5myxlgadl2s0dgke5",
            changeAddress: "addr1vyn6tvyc3daxl8wwvm2glay287dfa7xjgdm2jdl308ksy9canqafn"
        )
        
        let utxos = [
            CardanoUnspentOutput(address: "Ae2tdPwUPEZH7acU3Qm7L8HdDmw3fGMZ4Gg1wzfB9AMQH2nEgmjtSCWbFsJ",
                                 amount: 2330000,
                                 outputIndex: 0,
                                 transactionHash: "40a4a5d560d1d3fd5f2c943336b061176574136283f7bb407b50bdae1b44bc85"),
            CardanoUnspentOutput(address: "Ae2tdPwUPEZH7acU3Qm7L8HdDmw3fGMZ4Gg1wzfB9AMQH2nEgmjtSCWbFsJ",
                                 amount: 1630000,
                                 outputIndex: 1,
                                 transactionHash: "f5aebc99e4fc7d28d19ffc1c259a8b235f74f131446d841eb1015416b19b2095"),
        ]
        
        transactionBuilder.update(outputs: utxos)
        let dataForSign = try transactionBuilder.buildForSign(transaction: transaction)
        XCTAssertEqual(dataForSign.hex, "f1005767c73b782cdfab158b8ebf979646dbd546330011c6fdb0569b045deb92")
        
        // Sign
        let signature = Data(hexString: "5fa5cea0f8baa6e72b3c5d03d507966d532e4abe3d5f2729a927536e7967cf0e2157bd3d444250436ac1417fc5b0eda347cb705b64658e30dbb23db838efca05")
        let publicKey = Data(hexString:"de60f41ab5045ce1b9b37e386570ed63499a53ee93ca3073e54a80065678384d")
        let signatureInfo = SignatureInfo(signature: signature, publicKey: publicKey)
        let encoded = try transactionBuilder.buildForSend(transaction: transaction, signature: signatureInfo)
        
        XCTAssertEqual(
            encoded.hex,
            "83a4008282582040a4a5d560d1d3fd5f2c943336b061176574136283f7bb407b50bdae1b44bc8500825820f5aebc99e4fc7d28d19ffc1c259a8b235f74f131446d841eb1015416b19b209501018282583901558dd902616f5cd01edcc62870cb4748c45403f1228218bee5b628b526f0ca9e7a2c04d548fbd6ce86f358be139fe680652536437d1d6fd51a000f424082581d6127a5b0988b7a6f9dce66d48ff48a3f9a9ef8d24376a937f179ed02171a002ac997021a000260e9031a0b532b80a10081825820de60f41ab5045ce1b9b37e386570ed63499a53ee93ca3073e54a80065678384d58405fa5cea0f8baa6e72b3c5d03d507966d532e4abe3d5f2729a927536e7967cf0e2157bd3d444250436ac1417fc5b0eda347cb705b64658e30dbb23db838efca05f6"
        )
    }
}
