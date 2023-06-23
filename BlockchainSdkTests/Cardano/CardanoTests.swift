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
        XCTAssertEqual(walletCorePublicKey.data.hex, "6d8a0b425bd2ec9692af39b1c0cf0e51caa07a603550e22f54091e872c7df29003391c68824881ae3fc23a56a1a75ada3b96382db502e37564e84a5413cfaf12e554163344aafc2bbefe778a6953ddce0583c2f8e0a0686929c020ca33e06932154425dfbb01a2c5c042da411703603f89af89e57faae2946e2a5c18b1c5ca0e")
    }

    func test_address() {
        // when
        let address = AnyAddress(publicKey: walletCorePublicKey, coin: coinType)
        
        // then
        XCTAssertEqual(address.description, walletCoreAddress.description)
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
        do {
            let dataForSign = try transactionBuilder.buildForSign(transaction: transaction)
            
            // Sign
            let signature = try XCTUnwrap(walletCorePrivateKey.sign(digest: dataForSign, curve: coinType.curve))
            XCTAssertEqual(
                signature.hex,
                "7cf591599852b5f5e007fdc241062405c47e519266c0d884b0767c1d4f5eacce00db035998e53ed10ca4ba5ce4aac8693798089717ce6cf4415f345cc764200e"
            )
            
            let signatureInfo = SignatureInfo(signature: signature, publicKey: walletCorePublicKey.data)
            let encoded = try transactionBuilder.buildForSend(transaction: transaction, signature: signatureInfo)
            XCTAssertEqual(
                encoded.hex,
                "83a40082825820554f2fd942a23d06835d26bbd78f0106fa94c8a551114a0bef81927f66467af000825820f074134aabbfb13b8aec7cf5465b1e5a862bde5cb88532cc7e64619179b3e76701018282583901558dd902616f5cd01edcc62870cb4748c45403f1228218bee5b628b526f0ca9e7a2c04d548fbd6ce86f358be139fe680652536437d1d6fd51a006acfc082583901df58ee97ce7a46cd8bdeec4e5f3a03297eb197825ed5681191110804df22424b6880b39e4bac8c58de9fe6d23d79aaf44756389d827aa09b1a000ca96c021a000298d4031a032dcd55a100818258206d8a0b425bd2ec9692af39b1c0cf0e51caa07a603550e22f54091e872c7df29058407cf591599852b5f5e007fdc241062405c47e519266c0d884b0767c1d4f5eacce00db035998e53ed10ca4ba5ce4aac8693798089717ce6cf4415f345cc764200ef6"
            )
        } catch CardanoError.lowAda {
            // Ignore this error for WalletCore test
        } catch {
            throw error
        }
    }
}
