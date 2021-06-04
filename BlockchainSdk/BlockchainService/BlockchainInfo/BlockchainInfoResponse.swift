//
//  BlockchainInfoResponse.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 07.04.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

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
    
    private enum CodingKeys: String, CodingKey {
        case blockHeight = "block_height",
             balanceDif = "result",
             inputCount = "vin_sz",
             outputs = "out"
        case hash, inputs, time
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
    
    private enum CodingKeys: String, CodingKey {
        case hash = "tx_hash_big_endian",
             outputIndex = "tx_output_n",
             amount = "value",
             outputScript = "script"
    }
}
