//
//  TronNetworkModels.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 24.03.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

struct TronGetChainParametersResponse: Codable {
    struct TronChainParameter: Codable {
        let key: String
        let value: Int?
    }

    let chainParameter: [TronChainParameter]
}

struct TronChainParameters {
    let sunPerEnergyUnit: Int
    let dynamicEnergyMaxFactor: Int
}

struct TronAccountInfo {
    let balance: Decimal
    let tokenBalances: [Token: Decimal]
    let confirmedTransactionIDs: [String]
}

struct TronGetAccountRequest: Codable {
    let address: String
    let visible: Bool
}

struct TronGetAccountResponse: Codable {
    let balance: UInt64?
    // We don't use this field but we can't have just one optional `balance` field
    // Otherwise an empty JSON will conform to this structure
    let address: String
}

struct TronGetAccountResourceResponse: Codable {
    let freeNetUsed: Int?
    let freeNetLimit: Int
}

struct TronTransactionInfoRequest: Codable {
    let value: String
}

struct TronTransactionInfoResponse: Codable {
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

struct TronBroadcastRequest: Codable {
    let transaction: String
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
    struct TokenHistoryData: Codable {
        let energy_usage_total: Int?
    }
    
    let data: [TokenHistoryData]
}

struct TronContractEnergyUsageResponse: Codable {
    let energy_used: Int
}

struct TronContractInfoResponse: Codable {
    let contract_state: TronContractState
    
    struct TronContractState: Codable {
        let energy_factor: Int?
    }
}
