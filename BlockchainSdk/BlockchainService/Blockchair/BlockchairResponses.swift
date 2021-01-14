//
//  BlockchairResponse.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 14.02.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import BitcoinCore

struct BlockchairTransactionShort: Codable {
    let blockId: Int64
    let hash: String
    let time: Date
    let balanceChange: Double
}

struct BlockchairUtxo: Codable {
    let transactionHash: String?
    let index: Int?
    let value: UInt64?
}

struct BlockchairTransactionDetailed: Codable {
    let transaction: BlockchairTransaction
    let inputs: [BlockchairTxInput]
    let outputs: [BlockchairTxOutput]
    
    func pendingBtxTx(sourceAddress: String, decimalValue: Decimal) -> PendingTransaction {
        var destination: String = .unknown
        var source: String = .unknown
        var value: Decimal = 0
        var sequence: Int = SequenceValues.default.rawValue
        
        if let input = inputs.first(where:  { $0.recipient == sourceAddress }), let output = outputs.first(where: { $0.recipient != sourceAddress }) {
            source = input.recipient
            destination = output.recipient
            value = output.value
            sequence = input.spendingSequence
        } else if let output = outputs.first(where: { $0.recipient == sourceAddress }), let input = inputs.first(where: { $0.recipient != sourceAddress }) {
            destination = output.recipient
            source = input.recipient
            value = output.value
            sequence = input.spendingSequence
        }
        
        return PendingTransaction(hash: transaction.hash,
                                  destination: destination,
                                  value: value / decimalValue,
                                  source: source,
                                  fee: transaction.fee / decimalValue,
                                  date: transaction.time,
                                  isAlreadyRbf: false,
                                  sequence: sequence)
    }
}

struct BlockchairTransaction: Codable {
    let blockId: Int64
    let hash: String
    let time: Date
    let size: Int
    let lockTime: Int
    let inputCount: Int
    let outputCount: Int
    let inputTotal: Decimal
    let outputTotal: Decimal
    let fee: Decimal
}

struct BlockchairTxInput: Codable {
    let blockId: Int64
    let transactionHash: String
    let time: Date
    let value: Decimal
    let type: String
    let scriptHex: String
    let spendingSequence: Int
    let spendingSignatureHex: String
    let spendingWitness: String
    let recipient: String
}

struct BlockchairTxOutput: Codable {
    let blockId: Int64
    let transactionHash: String
    let time: Date
    let value: Decimal
    let type: String
    let recipient: String
    let scriptHex: String
}
