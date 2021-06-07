//
//  BlockchainInfoResponse.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 07.04.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import BitcoinCore

struct BlockchainInfoAddressResponse: Codable {
    let finalBalance: UInt64?
    let address: String?
    let transactions: [BlockchainInfoTransaction]?
	let transactionCount: Int?
    
    private enum CodingKeys: String, CodingKey {
        case finalBalance = "final_balance",
             transactions = "txs",
             transactionCount = "n_tx"
        case address
    }
}

struct BlockchainInfoFeeResponse: Codable {
    let regular: Int
    let priority: Int
}

struct BlockchainInfoInput: Codable {
    let sequence: Int?
    let witness: String?
    let script: String?
    let index: Int?
    let previousOutput: BlockchainInfoOutput?
    
    private enum CodingKeys: String, CodingKey {
        case previousOutput = "prev_out", index = "n"
        case sequence, witness, script
    }
}

struct BlockchainInfoOutput: Codable {
    let type: Int?
    let spent: Bool?
    let value: Int?
    let script: String?
    let address: String?
    
    private enum CodingKeys: String, CodingKey {
        case address = "addr"
        case type, spent, value, script
    }
}

struct BlockchainInfoTransaction: Codable {
    let hash: String?
    let blockHeight: UInt64?
	/// Balance difference. Using to recognize outgoing transaction for signature count
	let balanceDif: Int64?
    let inputCount: Int?
    let inputs: [BlockchainInfoInput]?
    let outputs: [BlockchainInfoOutput]?
    let time: Double?
    let fee: Int64?
    let doubleSpend: Bool?
    
    private enum CodingKeys: String, CodingKey {
        case blockHeight = "block_height",
             balanceDif = "result",
             inputCount = "vin_sz",
             outputs = "out",
             doubleSpend = "double_spend"
        case hash, inputs, time, fee
    }
    
    func toBasicTxData(userAddress: String, decimalValue: Decimal) -> BasicTransactionData? {
        guard
            let balanceDif = balanceDif,
            let hash = hash,
            let time = time
        else { return nil }
        
        let isIncoming = balanceDif > 0
        return BasicTransactionData(balanceDif: Decimal(balanceDif) / decimalValue,
                                    hash: hash,
                                    date: Date(seconds: time),
                                    isConfirmed: false,
                                    targetAddress: outputs?.first(where: { isIncoming ? $0.address == userAddress : $0.address != userAddress })?.address)
    }
    
    func toPendingTx(userAddress: String, decimalValue: Decimal) -> PendingTransaction? {
        var source: String = .unknown
        var destination: String = .unknown
        
        guard
            let balanceDif = balanceDif,
            let hash = hash
        else { return nil }
        
        let isIncoming = balanceDif > 0
        let date = time == nil ? Date() : Date(seconds: time!)
        if isIncoming {
            source = inputs?.first(where: { $0.previousOutput?.address != userAddress })?.previousOutput?.address ?? .unknown
            destination = userAddress
        } else {
            source = userAddress
            destination = outputs?.first(where: { $0.address != userAddress })?.address ?? .unknown
        }
        
        return PendingTransaction(hash: hash,
                                  destination: destination,
                                  value: Decimal(abs(balanceDif)) / decimalValue,
                                  source: source,
                                  fee: fee == nil ? nil : Decimal(fee!) / decimalValue,
                                  date: date,
                                  isAlreadyRbf: doubleSpend ?? false,
                                  sequence: inputs?.max(by: { $0.sequence ?? 0 > $1.sequence ?? 0 })?.sequence ?? SequenceValues.default.rawValue)
    }
}

struct BlockchainInfoUnspentResponse: Codable  {
    let unspentOutputs: [BlockchainInfoUtxo]?
    
    private enum CodingKeys: String, CodingKey {
        case unspentOutputs = "unspent_outputs"
    }
}

struct BlockchainInfoUtxo: Codable {
    let hash: String?
    let outputIndex: Int?
    let amount: UInt64?
    let outputScript: String?
    let confirmations: Int?
    
    private enum CodingKeys: String, CodingKey {
        case hash = "tx_hash_big_endian",
             outputIndex = "tx_output_n",
             amount = "value",
             outputScript = "script",
             confirmations
    }
}
