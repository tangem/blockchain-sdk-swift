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
    let blockchain = BlockchainSdk.Blockchain.cardano
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
            fee: Fee(.zeroCoin(for: blockchain)),
            sourceAddress: "addr1vyn6tvyc3daxl8wwvm2glay287dfa7xjgdm2jdl308ksy9canqafn",
            destinationAddress: "addr1q90uh2eawrdc9vaemftgd50l28yrh9lqxtjjh4z6dnn0u7ggasexxdyyk9f05atygnjlccsjsggtc87hhqjna32fpv5qeq96ls",
            changeAddress: "addr1vyn6tvyc3daxl8wwvm2glay287dfa7xjgdm2jdl308ksy9canqafn"
        )
        
        let utxos = [
            CardanoUnspentOutput(address: "addr1vyn6tvyc3daxl8wwvm2glay287dfa7xjgdm2jdl308ksy9canqafn",
                                 amount: 2500000,
                                 outputIndex: 0,
                                 transactionHash: "1992f01dfd9a94d7a2896617a96b3deb5f007ca32e8860e7c1720714ae6a17e5",
                                 assets: []),
            CardanoUnspentOutput(address: "addr1vyn6tvyc3daxl8wwvm2glay287dfa7xjgdm2jdl308ksy9canqafn",
                                 amount: 1450000,
                                 outputIndex: 0,
                                 transactionHash: "2a14228eb7d7ac30ed019ec139f0120e4538fb3f6d52dd97c8d416468ef87c24",
                                 assets: []),
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
            fee: Fee(.zeroCoin(for: blockchain)),
            sourceAddress: "addr1vyn6tvyc3daxl8wwvm2glay287dfa7xjgdm2jdl308ksy9canqafn",
            destinationAddress: "Ae2tdPwUPEZ4kps4As3f38H3gyjMs2YoMdJVMCq3UQzK4zhLunRriZpfbhs",
            changeAddress: "addr1vyn6tvyc3daxl8wwvm2glay287dfa7xjgdm2jdl308ksy9canqafn"
        )
        
        let utxos = [
            CardanoUnspentOutput(address: "addr1vyn6tvyc3daxl8wwvm2glay287dfa7xjgdm2jdl308ksy9canqafn",
                                 amount: 1981037,
                                 outputIndex: 1,
                                 transactionHash: "db2306d819d848f67f70ab898028d9827e5d1fccc7033531534fdd39e93a796e",
                                 assets: []),
            CardanoUnspentOutput(address: "Ae2tdPwUPEZH7acU3Qm7L8HdDmw3fGMZ4Gg1wzfB9AMQH2nEgmjtSCWbFsJ",
                                 amount: 1300000,
                                 outputIndex: 0,
                                 transactionHash: "848c0861a3dc02a806d71cb35de83ffbc2a8553d161e2449c37572d7c2de44a7",
                                 assets: []),
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
    
    // Successful transaction
    // https://cardanoscan.io/transaction/3ac6b76c63e109494823fe13e6f6d52544896a5ab81ae711ce56f039d6777bd1
    func testSignTransferToken() throws {
        let token = Token(
            name: "SingularityNET",
            symbol: "AGIX",
            contractAddress: "f43a62fdc3965df486de8a0d32fe800963589c41b38946602a0dc535",
            decimalCount: 8
        )
        
        let transaction = Transaction(
            amount: Amount(with: blockchain, type: .token(value: token), value: 0.65),
            fee: Fee(.zeroCoin(for: blockchain)), // Will not be used
            sourceAddress: "addr1vyn6tvyc3daxl8wwvm2glay287dfa7xjgdm2jdl308ksy9canqafn",
            destinationAddress: "addr1qx55ymlqemndq8gluv40v58pu76a2tp4mzjnyx8n6zrp2vtzrs43a0057y0edkn8lh9su8vh5lnhs4npv6l9tuvncv8swc7t08",
            changeAddress: "addr1vyn6tvyc3daxl8wwvm2glay287dfa7xjgdm2jdl308ksy9canqafn"
        )
        
        let utxos = [
            CardanoUnspentOutput(address: "addr1vyn6tvyc3daxl8wwvm2glay287dfa7xjgdm2jdl308ksy9canqafn",
                                 amount: 1796085,
                                 outputIndex: 1,
                                 transactionHash: "03946fe122634d05e93219fde628ce55a5e0d06f23afa456864897357c5dade8",
                                 assets: []),
            CardanoUnspentOutput(address: "addr1vyn6tvyc3daxl8wwvm2glay287dfa7xjgdm2jdl308ksy9canqafn",
                                 amount: 1500000,
                                 outputIndex: 0,
                                 transactionHash: "482d88eb2d3b40b8a4e6bb8545cef842a5703e8f9eab9e3caca5c2edd1f31a7f",
                                 assets: [
                                    CardanoUnspentOutput.Asset(
                                        policyID: "f43a62fdc3965df486de8a0d32fe800963589c41b38946602a0dc535",
                                        assetNameHex: "41474958",
                                        amount: 50000000
                                    )
                                 ]),
            CardanoUnspentOutput(address: "addr1vyn6tvyc3daxl8wwvm2glay287dfa7xjgdm2jdl308ksy9canqafn",
                                 amount: 1127821,
                                 outputIndex: 0,
                                 transactionHash: "967e971cb5bcb1723ef24140c6d6689eb6453548ee47478996dcc6677ce7f62f",
                                 assets: []),
            CardanoUnspentOutput(address: "addr1vyn6tvyc3daxl8wwvm2glay287dfa7xjgdm2jdl308ksy9canqafn",
                                 amount: 3384392,
                                 outputIndex: 1,
                                 transactionHash: "d5958a70c20fdc7aa3537bf830730b1cef3dd5b2d12dc0360be130a18df71cd9",
                                 assets: [
                                    CardanoUnspentOutput.Asset(
                                        policyID: "f43a62fdc3965df486de8a0d32fe800963589c41b38946602a0dc535",
                                        assetNameHex: "41474958",
                                        amount: 42070000
                                    )
                                 ]),
        ]
        
        transactionBuilder.update(outputs: utxos)
        let dataForSign = try transactionBuilder.buildForSign(transaction: transaction)
        XCTAssertEqual(dataForSign.hex, "3ac6b76c63e109494823fe13e6f6d52544896a5ab81ae711ce56f039d6777bd1")
        
        // Sign
        let signature = Data(hex: "a3c14e049b3192c64af175ff3650f9c0a6f833d168634b3ec73f2f5609bce107d2e39a1387c844bbe521bf3d11a63c4927f62a7c06dc40a8c28da74cb072d70d")
        let publicKey = Data(hex: "de60f41ab5045ce1b9b37e386570ed63499a53ee93ca3073e54a80065678384d")
        
        let signatureInfo = SignatureInfo(signature: signature, publicKey: publicKey)
        let encoded = try transactionBuilder.buildForSend(transaction: transaction, signature: signatureInfo)
        
        XCTAssertEqual(
            encoded.hex,
            "83a40084825820d5958a70c20fdc7aa3537bf830730b1cef3dd5b2d12dc0360be130a18df71cd90182582003946fe122634d05e93219fde628ce55a5e0d06f23afa456864897357c5dade801825820482d88eb2d3b40b8a4e6bb8545cef842a5703e8f9eab9e3caca5c2edd1f31a7f00825820967e971cb5bcb1723ef24140c6d6689eb6453548ee47478996dcc6677ce7f62f00018282583901a9426fe0cee6d01d1fe32af650e1e7b5d52c35d8a53218f3d0861531621c2b1ebdf4f11f96da67fdcb0e1d97a7e778566166be55f193c30f821a00160a5ba1581cf43a62fdc3965df486de8a0d32fe800963589c41b38946602a0dc535a144414749581a03dfd24082581d6127a5b0988b7a6f9dce66d48ff48a3f9a9ef8d24376a937f179ed0217821a005e6b9da1581cf43a62fdc3965df486de8a0d32fe800963589c41b38946602a0dc535a144414749581a019d0e30021a0002af32031a0b532b80a10081825820de60f41ab5045ce1b9b37e386570ed63499a53ee93ca3073e54a80065678384d5840a3c14e049b3192c64af175ff3650f9c0a6f833d168634b3ec73f2f5609bce107d2e39a1387c844bbe521bf3d11a63c4927f62a7c06dc40a8c28da74cb072d70df6"
        )
    }
}
