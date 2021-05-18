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
    let transactions: [BlockchainInfoTransaction]?
	let transactionCount: Int?
    
    private enum CodingKeys: String, CodingKey {
        case finalBalance = "final_balance",
             transactions = "txs",
             transactionCount = "n_tx"
    }
}

struct BlockchainInfoFeeResponse: Codable {
    let regular: Int
    let priority: Int
}

struct BlockchainInfoTransaction: Codable {
    let hash: String?
    let blockHeight: UInt64?
	/// Balance difference. Using to recognize outgoing transaction for signature count
	let balanceDif: Int64?
    let inputCount: Int?
    let time: Double?
    
    private enum CodingKeys: String, CodingKey {
        case hash,
             blockHeight = "block_height",
             balanceDif = "result",
             inputCount = "vin_sz",
             time
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
