//
//  TransactionRecord.swift
//  BlockchainSdk
//
//  Created by Andrew Son on 27/01/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

public struct TransactionRecord {
    let uid: String
    let transactionHash: String
    let transactionIndex: Int
    let interTransactionIndex: Int
    let status: SpvTransactionStatus
    let type: SpvTransactionType
    let blockHeight: Int?
    let amount: Decimal
    let fee: Decimal?
    let date: Date
    let from: [SpvTransactionInputOutput]
    let to: [SpvTransactionInputOutput]
    let conflictingHash: String?
    var transactionExtraType: String?
}

public struct SpvTransactionInputOutput {
    let mine: Bool
    let address: String?
    let value: Int?
    let changeOutput: Bool
}

public enum SpvTransactionStatus: Int {
    case new, relayed, invalid
}

public enum SpvTransactionType {
    case incoming, outgoing, sentToSelf(enteredAmount: Decimal)

    var description: String {
        switch self {
        case .incoming: return "incoming"
        case .outgoing: return "outgoing"
        case .sentToSelf(let possibleEnteredAmount): return "sentToSelf: \(possibleEnteredAmount.formattedAmount)"
        }
    }

}

public extension Decimal {
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.generatesDecimalNumbers = true
        formatter.minimumIntegerDigits = 1
        formatter.minimumFractionDigits = 8
        formatter.maximumFractionDigits = 8
        return formatter.string(from: self as NSDecimalNumber)!
    }
}
