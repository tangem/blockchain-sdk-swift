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
            fee: .zero(for: blockchain),
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
}
