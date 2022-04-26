//
//  TronRequest.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 24.03.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation


struct TronAccountInfo {
    let balance: Decimal
    let tokenBalances: [Token: Decimal]
    let confirmedTransactionIDs: [String]
}

struct TronGetAccountRequest: Codable {
    let address: String
    let visible: Bool
}

struct TronTransactionInfo: Codable {
    let id: String
}

struct TronBlock: Codable {
    struct BlockHeader: Codable {
        struct RawData: Codable {
            let number: Int64
            let txTrieRoot: String
            let witness_address: String
            let parentHash: String
            let version: Int32
            let timestamp: Int64
        }
        
        let raw_data: RawData
    }
    
    let block_header: BlockHeader
}

struct TronBroadcastResponse: Codable {
    let result: Bool
    let txid: String
}

struct TronTriggerSmartContractRequest: Codable {
    let owner_address: String
    let contract_address: String
    let function_selector: String
    var fee_limit: UInt64? = nil
    let parameter: String
    let visible: Bool
}

struct TronTriggerSmartContractResponse: Codable {
    let constant_result: [String]
}

struct TronTokenHistoryResponse: Codable {
    struct Data: Codable {
        let energy_usage_total: Int
    }
    
    let data: [Data]
}
