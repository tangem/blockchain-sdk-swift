//
//  ChiaModels.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 17.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct ChiaPuzzleHashBody: Encodable {
    let puzzleHash: String
}

struct ChiaTransactionBody {
    let spendBundle: ChiaSpendBundle
}

struct ChiaSpendBundle {
    let aggregatedSignature: String
    let coinSpends: ChiaCoinSpend
}

struct ChiaCoinSpend {
    let coin: ChiaCoin
    let puzzleReveal: String
    let solution: String
}

struct ChiaCoin: Decodable {
    // Has to be encoded as a number in JSON, therefore Long is used. It's enough to encode ~1/3 of Chia total supply.
    let amount: Int64
    let parentCoinInfo: String
    let puzzleHash: String
}
