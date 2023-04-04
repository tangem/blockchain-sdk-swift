//
//  RavencoinWalletUTXO.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 03.04.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct RavencoinWalletUTXO: Decodable {
    let address: String
    let txid: String
    let vout: Int
    let scriptPubKey: String
    let assetName: String
    let amount: Int
    let satoshis: Int
    let height: Int
    let confirmations: Int
}
