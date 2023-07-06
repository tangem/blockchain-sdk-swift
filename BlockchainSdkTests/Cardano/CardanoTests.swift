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
    let blockchain = Blockchain.cardano(shelley: true)
    let coinType = CoinType.cardano

    override func setUp() {
        super.setUp()
        transactionBuilder = CardanoTransactionBuilder()
    }

    // Successful transaction
    // https://cardanoscan.io/transaction/db2306d819d848f67f70ab898028d9827e5d1fccc7033531534fdd39e93a796e
    func testSignTransfer() throws {
        let transaction = Transaction(
            amount: Amount(with: blockchain, value: 1.8),
            fee: .zero(for: blockchain),
            sourceAddress: "addr1vyn6tvyc3daxl8wwvm2glay287dfa7xjgdm2jdl308ksy9canqafn",
            destinationAddress: "addr1q90uh2eawrdc9vaemftgd50l28yrh9lqxtjjh4z6dnn0u7ggasexxdyyk9f05atygnjlccsjsggtc87hhqjna32fpv5qeq96ls",
            changeAddress: "addr1vyn6tvyc3daxl8wwvm2glay287dfa7xjgdm2jdl308ksy9canqafn"
        )
        
        let utxos = [
            CardanoUnspentOutput(address: "addr1vyn6tvyc3daxl8wwvm2glay287dfa7xjgdm2jdl308ksy9canqafn",
                                 amount: 2500000,
                                 outputIndex: 0,
                                 transactionHash: "1992f01dfd9a94d7a2896617a96b3deb5f007ca32e8860e7c1720714ae6a17e5"),
            CardanoUnspentOutput(address: "addr1vyn6tvyc3daxl8wwvm2glay287dfa7xjgdm2jdl308ksy9canqafn",
                                 amount: 1450000,
                                 outputIndex: 0,
                                 transactionHash: "2a14228eb7d7ac30ed019ec139f0120e4538fb3f6d52dd97c8d416468ef87c24"),
        ]

        transactionBuilder.update(outputs: utxos)
        
        let dataForSign = try transactionBuilder.buildForSign(transaction: transaction)
        XCTAssertEqual(
            dataForSign.hex,
            "db2306d819d848f67f70ab898028d9827e5d1fccc7033531534fdd39e93a796e"
        )
        
        // Sign
        let signature = Data(hex: "d110d0ae92016c4edf0eefb2c54ad71b4e9b27f8427f6bd895e94f3beded57f839deecea4f50a3ff6730409b323fa2b07c1e1529e8ebbdebb5138b5ee2f4ab09")
        let publicKey = Data(hex: "de60f41ab5045ce1b9b37e386570ed63499a53ee93ca3073e54a80065678384d")
        
        let signatureInfo = SignatureInfo(signature: signature, publicKey: publicKey)
        let encoded = try transactionBuilder.buildForSend(transaction: transaction, signature: signatureInfo)
        XCTAssertEqual(
            encoded.hex,
            "83a400828258201992f01dfd9a94d7a2896617a96b3deb5f007ca32e8860e7c1720714ae6a17e5008258202a14228eb7d7ac30ed019ec139f0120e4538fb3f6d52dd97c8d416468ef87c24000182825839015fcbab3d70db82b3b9da5686d1ff51c83b97e032e52bd45a6ce6fe7908ec32633484b152fa756444e5fc62128210bc1fd7b8253ec5490b281a001b774082581d6127a5b0988b7a6f9dce66d48ff48a3f9a9ef8d24376a937f179ed02171a001e3a6d021a00029403031a0b532b80a10081825820de60f41ab5045ce1b9b37e386570ed63499a53ee93ca3073e54a80065678384d5840d110d0ae92016c4edf0eefb2c54ad71b4e9b27f8427f6bd895e94f3beded57f839deecea4f50a3ff6730409b323fa2b07c1e1529e8ebbdebb5138b5ee2f4ab09f6"
        )
    }
    
    // Successful transaction
    // https://cardanoscan.io/transaction/03946fe122634d05e93219fde628ce55a5e0d06f23afa456864897357c5dade8
    func testSignTransferFromLegacy() throws {
        let transaction = Transaction(
            amount: Amount(with: blockchain, value: 1.3),
            fee: .zero(for: blockchain),
            sourceAddress: "addr1vyn6tvyc3daxl8wwvm2glay287dfa7xjgdm2jdl308ksy9canqafn",
            destinationAddress: "Ae2tdPwUPEZ4kps4As3f38H3gyjMs2YoMdJVMCq3UQzK4zhLunRriZpfbhs",
            changeAddress: "addr1vyn6tvyc3daxl8wwvm2glay287dfa7xjgdm2jdl308ksy9canqafn"
        )
        
        let utxos = [
            CardanoUnspentOutput(address: "addr1vyn6tvyc3daxl8wwvm2glay287dfa7xjgdm2jdl308ksy9canqafn",
                                 amount: 1981037,
                                 outputIndex: 1,
                                 transactionHash: "db2306d819d848f67f70ab898028d9827e5d1fccc7033531534fdd39e93a796e"),
            CardanoUnspentOutput(address: "Ae2tdPwUPEZH7acU3Qm7L8HdDmw3fGMZ4Gg1wzfB9AMQH2nEgmjtSCWbFsJ",
                                 amount: 1300000,
                                 outputIndex: 0,
                                 transactionHash: "848c0861a3dc02a806d71cb35de83ffbc2a8553d161e2449c37572d7c2de44a7"),
        ]
        
        transactionBuilder.update(outputs: utxos)
        let dataForSign = try transactionBuilder.buildForSign(transaction: transaction)
        XCTAssertEqual(dataForSign.hex, "03946fe122634d05e93219fde628ce55a5e0d06f23afa456864897357c5dade8")
        
        // Sign
        let signature = Data(hex: "d0cd5a183e63dce8f0d5bc6d617bbc2f3aa982fd24ece4e29eb10abb69c00bc8dd9d353f35084c5bcc9f81d4599e9c67980ebce32e3462951116ee39da1da406")
        let publicKey = Data(hex: "de60f41ab5045ce1b9b37e386570ed63499a53ee93ca3073e54a80065678384d")
        
        let signatureInfo = SignatureInfo(signature: signature, publicKey: publicKey)
        let encoded = try transactionBuilder.buildForSend(transaction: transaction, signature: signatureInfo)
        
        XCTAssertEqual(
            encoded.hex,
            "83a40082825820db2306d819d848f67f70ab898028d9827e5d1fccc7033531534fdd39e93a796e01825820848c0861a3dc02a806d71cb35de83ffbc2a8553d161e2449c37572d7c2de44a700018282582b82d818582183581c4fab3a1dbcaec5ed582dc34219b0147b972c35f201b73a446105719ea0001aa351d8aa1a0013d62082581d6127a5b0988b7a6f9dce66d48ff48a3f9a9ef8d24376a937f179ed02171a001b67f5021a0002d278031a0b532b80a20081825820de60f41ab5045ce1b9b37e386570ed63499a53ee93ca3073e54a80065678384d5840d0cd5a183e63dce8f0d5bc6d617bbc2f3aa982fd24ece4e29eb10abb69c00bc8dd9d353f35084c5bcc9f81d4599e9c67980ebce32e3462951116ee39da1da4060281845820de60f41ab5045ce1b9b37e386570ed63499a53ee93ca3073e54a80065678384d5840d0cd5a183e63dce8f0d5bc6d617bbc2f3aa982fd24ece4e29eb10abb69c00bc8dd9d353f35084c5bcc9f81d4599e9c67980ebce32e3462951116ee39da1da4065820000000000000000000000000000000000000000000000000000000000000000041a0f6"
        )
    }
}

/*
 
 func testSignTransferFromLegacy2() throws {
     let privateKey = PrivateKey(data: Data(hexString: "98f266d1aac660179bc2f456033941238ee6b2beb8ed0f9f34c9902816781f5a9903d1d395d6ab887b65ea5e344ef09b449507c21a75f0ce8c59d0ed1c6764eba7f484aa383806735c46fd769c679ee41f8952952036a6e2338ada940b8a91f4e890ca4eb6bec44bf751b5a843174534af64d6ad1f44e0613db78a7018781f5aa151d2997f52059466b715d8eefab30a78b874ae6ef4931fa58bb21ef8ce2423d46f19d0fbf75afb0b9a24e31d533f4fd74cee3b56e162568e8defe37123afc4")!)!
     let publicKey = privateKey.getPublicKeyEd25519Cardano()
     let byronAddress = Cardano.getByronAddress(publicKey: publicKey)
     
//        print("->>", AnyAddress(publicKey: publicKey, coin: .cardano).description)
     
     XCTAssertEqual(
         byronAddress,
         "Ae2tdPwUPEZ6vkqxSjJxaQYmDxHf5DTnxtZ67pFLJGTb9LTnCGkDP6ca3f8"
     )
     XCTAssertEqual(
         publicKey.data.hexString,
     "d163c8c4f0be7c22cd3a1152abb013c855ea614b92201497a568c5d93ceeb41ea7f484aa383806735c46fd769c679ee41f8952952036a6e2338ada940b8a91f40b5aaa6103dc10842894a1eeefc5447b9bcb9bcf227d77e57be195d17bc03263d46f19d0fbf75afb0b9a24e31d533f4fd74cee3b56e162568e8defe37123afc4"
     )
     
     var input = CardanoSigningInput.with {
         $0.transferMessage.toAddress = "addr1q90uh2eawrdc9vaemftgd50l28yrh9lqxtjjh4z6dnn0u7ggasexxdyyk9f05atygnjlccsjsggtc87hhqjna32fpv5qeq96ls"
         $0.transferMessage.changeAddress = "addr1qx55ymlqemndq8gluv40v58pu76a2tp4mzjnyx8n6zrp2vtzrs43a0057y0edkn8lh9su8vh5lnhs4npv6l9tuvncv8swc7t08"
         $0.transferMessage.amount = 3000000
         $0.ttl = 190000000
     }
     
//        let signature = privateKey.sign(digest: Data(hexString: "72F708EE40BE57C05F9350538E78E439EFA50B4CD5A205FB078298DEA9DC90D0")!, curve: .ed25519ExtendedCardano)
//        print("signature", signature?.hexString)
//        print("publicKey", publicKey.data.hexString)
     
//        input.privateKey.append(privateKey.data)

     let utxo1 = CardanoTxInput.with {
         $0.outPoint.txHash = Data(hexString: "8316e5007d61fb90652cabb41141972a38b5bc60954d602cf843476aa3f67f63")!
         $0.outPoint.outputIndex = 0
         $0.address = "Ae2tdPwUPEZ6vkqxSjJxaQYmDxHf5DTnxtZ67pFLJGTb9LTnCGkDP6ca3f8"
         $0.amount = 2500000
     }
     input.utxos.append(utxo1)

     let utxo2 = CardanoTxInput.with {
         $0.outPoint.txHash = Data(hexString: "e29392c59c903fefb905730587d22cae8bda30bd8d9aeec3eca082ae77675946")!
         $0.outPoint.outputIndex = 0
         $0.address = "Ae2tdPwUPEZ6vkqxSjJxaQYmDxHf5DTnxtZ67pFLJGTb9LTnCGkDP6ca3f8"
         $0.amount = 1700000
     }
     input.utxos.append(utxo2)
//        input.plan = AnySigner.plan(input: input, coin: .cardano)
     
     let txInputData = try input.serializedData()
     let preImageHashes = TransactionCompiler.preImageHashes(coinType: .cardano, txInputData: txInputData)
     
     let preSigningOutput = try TxCompilerPreSigningOutput(serializedData: preImageHashes)
     XCTAssertEqual(preSigningOutput.error, .ok)
             
     // Sign
     let signature = try XCTUnwrap(privateKey.sign(digest: preSigningOutput.dataHash, curve: .ed25519ExtendedCardano))
     XCTAssertEqual(
         signature.hexString,
         "6a23ab9267867fbf021c1cb2232bc83d2cdd663d651d22d59b6cddbca5cb106d4db99da50672f69a2309ca8a329a3f9576438afe4538b013de4591a6dfcd4d09"
     )
     
     // Fill vectors. Vectors should be equal size
     let signatureVec = DataVector()
     signatureVec.add(data: signature)
     
     let pubkeyVec = DataVector()
     pubkeyVec.add(data: publicKey.data)
     
     let compileWithSignatures = TransactionCompiler.compileWithSignaturesAndPubKeyType(
         coinType: .cardano,
         txInputData: txInputData,
         signatures: signatureVec,
         publicKeys: pubkeyVec,
         pubKeyType: .ed25519Cardano
     )
     let output2: CardanoSigningOutput = try CardanoSigningOutput(serializedData: compileWithSignatures)
     XCTAssertEqual(output2.error, .ok)
     
     XCTAssertEqual(output2.encoded.hexString,
         "83a400828258208316e5007d61fb90652cabb41141972a38b5bc60954d602cf843476aa3f67f6300825820e29392c59c903fefb905730587d22cae8bda30bd8d9aeec3eca082ae77675946000182825839015fcbab3d70db82b3b9da5686d1ff51c83b97e032e52bd45a6ce6fe7908ec32633484b152fa756444e5fc62128210bc1fd7b8253ec5490b281a002dc6c082583901a9426fe0cee6d01d1fe32af650e1e7b5d52c35d8a53218f3d0861531621c2b1ebdf4f11f96da67fdcb0e1d97a7e778566166be55f193c30f1a000f9ec1021a0002b0bf031a0b532b80a20081825820d163c8c4f0be7c22cd3a1152abb013c855ea614b92201497a568c5d93ceeb41e58406a23ab9267867fbf021c1cb2232bc83d2cdd663d651d22d59b6cddbca5cb106d4db99da50672f69a2309ca8a329a3f9576438afe4538b013de4591a6dfcd4d090281845820d163c8c4f0be7c22cd3a1152abb013c855ea614b92201497a568c5d93ceeb41e58406a23ab9267867fbf021c1cb2232bc83d2cdd663d651d22d59b6cddbca5cb106d4db99da50672f69a2309ca8a329a3f9576438afe4538b013de4591a6dfcd4d095820a7f484aa383806735c46fd769c679ee41f8952952036a6e2338ada940b8a91f441a0f6")

     // Sign
//        let output: CardanoSigningOutput = AnySigner.sign(input: input, coin: .cardano)
//        XCTAssertEqual(output.error, TW_Common_Proto_SigningError.ok)

//        let encoded = output.encoded
//        XCTAssertEqual(encoded.hexString,
//            "83a400828258208316e5007d61fb90652cabb41141972a38b5bc60954d602cf843476aa3f67f6300825820e29392c59c903fefb905730587d22cae8bda30bd8d9aeec3eca082ae77675946000182825839015fcbab3d70db82b3b9da5686d1ff51c83b97e032e52bd45a6ce6fe7908ec32633484b152fa756444e5fc62128210bc1fd7b8253ec5490b281a002dc6c082583901a9426fe0cee6d01d1fe32af650e1e7b5d52c35d8a53218f3d0861531621c2b1ebdf4f11f96da67fdcb0e1d97a7e778566166be55f193c30f1a000f9ec1021a0002b0bf031a0b532b80a20081825820d163c8c4f0be7c22cd3a1152abb013c855ea614b92201497a568c5d93ceeb41e58406a23ab9267867fbf021c1cb2232bc83d2cdd663d651d22d59b6cddbca5cb106d4db99da50672f69a2309ca8a329a3f9576438afe4538b013de4591a6dfcd4d090281845820d163c8c4f0be7c22cd3a1152abb013c855ea614b92201497a568c5d93ceeb41e58406a23ab9267867fbf021c1cb2232bc83d2cdd663d651d22d59b6cddbca5cb106d4db99da50672f69a2309ca8a329a3f9576438afe4538b013de4591a6dfcd4d095820000000000000000000000000000000000000000000000000000000000000000041a0f6")
     
//        XCTAssertEqual(encoded.hexString, output2.encoded.hexString)
//        XCTAssertEqual(output.txID.hexString, output2.txID.hexString)

//        let txid = output.txID
//        XCTAssertEqual(txid.hexString, "d6d60ff90c708deedfd228ed5b810f0c2e9427ec3c0edd1cbd615ce113a724f5")
 }
 */
