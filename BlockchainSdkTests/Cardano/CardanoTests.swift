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
    var outputs: [CardanoUnspentOutput] = []

    let publicKey = Data(hex: "35E60B25785480A2105F378945DEF8048009212825A8685406C47D3901B836AB")
    let tangemWalletAddress = "addr1v9jlkv7lv2m4zxqyljd2jjajw8n27v6gjpuznya09zavu7c5r9mxs"

    var walletCorePublicKey: PublicKey {
        PublicKey(
            data: Data(hex: "fafa7eb4146220db67156a03a5f7a79c666df83eb31abbfbe77c85e06d40da3110f3245ddf9132ecef98c670272ef39c03a232107733d4a1d28cb53318df26faf4b8d5201961e68f2e177ba594101f513ee70fe70a41324e8ea8eb787ffda6f4bf2eea84515a4e16c4ff06c92381822d910b5cbf9e9c144e1fb76a6291af7276"),
            type: coinType.publicKeyType
        )!
    }

    // addr1vyn6tvyc3daxl8wwvm2glay287dfa7xjgdm2jdl308ksy9canqafn
    var walletCoreAddress: AnyAddress {
        AnyAddress(
            string: "addr1qxxe304qg9py8hyyqu8evfj4wln7dnms943wsugpdzzsxnkvvjljtzuwxvx0pnwelkcruy95ujkq3aw6rl0vvg32x35qc92xkq",
            coin: coinType
        )!
    }

    let coinType = CoinType.cardano

    override func setUp() {
        super.setUp()
//        continueAfterFailure = false

        transactionBuilder = CardanoTransactionBuilder(walletPublicKey: <#T##Wallet.PublicKey#>)

        outputs = [
            CardanoUnspentOutput(
                address: "addr1qx55ymlqemndq8gluv40v58pu76a2tp4mzjnyx8n6zrp2vtzrs43a0057y0edkn8lh9su8vh5lnhs4npv6l9tuvncv8swc7t08",
                amount: 5316591,
                outputIndex: 1,
                transactionHash: "cde74834c41bfd276b860fa7c33a5a0503385f3b4eb6556ab0738c0e6e35cf96"
            )
        ]

    }

    func test_address() throws {
        let address = AnyAddress(publicKey: walletCorePublicKey, coin: coinType)
        XCTAssertEqual(address.description, walletCoreAddress.description)
    }

    func test_build_tx() throws {
        transactionBuilder.unspentOutputs = outputs
        let transaction = Transaction(
            amount: Amount(with: .cardano(shelley: true), value: 1),
            fee: Fee(Amount(with: .cardano(shelley: true), value: 0.1)),
            sourceAddress: tangemWalletAddress,
            destinationAddress: walletCoreAddress.description,
            changeAddress: tangemWalletAddress
        )
        let walletAmount = outputs.reduce(0, { $0 + $1.amount })

        let (hash, cbor) = try transactionBuilder.buildForSign(
            transaction: transaction,
            walletAmount: Decimal(walletAmount),
            isEstimated: false
        )

//        WalletCore.CardanoSigningInput

//        XCTAssertEqual(hash.hex, "2ff8fc42ce3d1871aad5e9cb2da24c2f78a25b2a49011367b4d4c09cdbaccdaa")
//        XCTAssertEqual(cbor.encode(), [164, 1, 130, 130, 88, 57, 1, 141, 152, 190, 160, 65, 66, 67, 220, 132, 7, 15, 150, 38, 85, 119, 231, 230, 207, 112, 45, 98, 232, 113, 1, 104, 133, 3, 78, 204, 100, 191, 37, 139, 142, 51, 12, 240, 205, 217, 253, 176, 62, 16, 180, 228, 172, 8, 245, 218, 31, 222, 198, 34, 42, 52, 104, 26, 0, 15, 66, 64, 130, 88, 29, 97, 101, 251, 51, 223, 98, 183, 81, 24, 4, 252, 154, 169, 75, 178, 113, 230, 175, 51, 72, 144, 120, 41, 147, 175, 40, 186, 206, 123, 27, 0, 0, 4, 213, 221, 115, 208, 224, 2, 26, 0, 1, 134, 160, 0, 129, 130, 88, 32, 205, 231, 72, 52, 196, 27, 253, 39, 107, 134, 15, 167, 195, 58, 90, 5, 3, 56, 95, 59, 78, 182, 85, 106, 176, 115, 140, 14, 110, 53, 207, 150, 1, 3, 26, 11, 83, 43, 128])

        print("buildForSign ->> data", hash.hex)
        print("buildForSign ->> hash cbor", "\(cbor.encode())")
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
