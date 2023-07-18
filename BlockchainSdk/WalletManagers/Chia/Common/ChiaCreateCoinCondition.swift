//
//  ChiaCreateCoinCondition.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 18.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct CreateCoinCondition {
    private let destinationPuzzleHash: Data
    private let amount: Int64
    private let memos: Data = Data()
    
    init(destinationPuzzleHash: Data, amount: Int64) {
        self.destinationPuzzleHash = destinationPuzzleHash
        self.amount = amount
    }
}
