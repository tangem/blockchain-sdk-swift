//
//  ChiaCreateCoinCondition.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 18.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

protocol ChiaCondition {
    var conditionCode: UInt64 { get set }

    func toProgram() -> ClvmProgram
}

struct CreateCoinCondition: ChiaCondition {
    var conditionCode: UInt64 = 51
    
    private let destinationPuzzleHash: Data
    private let amount: UInt64
    private let memos: Data
    
    init(destinationPuzzleHash: Data, amount: UInt64, memos: Data = Data()) {
        self.destinationPuzzleHash = destinationPuzzleHash
        self.amount = amount
        self.memos = memos
    }
}

extension CreateCoinCondition {
    func toProgram() -> ClvmProgram {
        var programList = [
            ClvmProgram.from(long: conditionCode),
            ClvmProgram.from(bytes: destinationPuzzleHash.bytes),
            ClvmProgram.from(long: amount)
        ]

        if !memos.isEmpty {
            programList.append(
                ClvmProgram.from(list: [ClvmProgram.from(bytes: memos.bytes)])
            )
        }

        return ClvmProgram.from(list: programList)
    }
}

// always valid condition
struct RemarkCondition: ChiaCondition {
    var conditionCode: UInt64 = 1
    
    func toProgram() -> ClvmProgram {
        ClvmProgram.from(list: [])
    }
}
