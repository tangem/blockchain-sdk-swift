//
//  TronRequest.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 24.03.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

struct TronGetAccountRequest: Codable {
    let address: String
    let visible: Bool
}

struct TronCreateTransactionRequest: Codable {
    let owner_address: String
    let to_address: String
    let amount: UInt64
    let visible: Bool
}

struct TronTransactionRequest: Codable {
    struct RawData: Codable {
        let contract: [Contract]
        let ref_block_bytes: String
        let ref_block_hash: String
        let expiration: UInt64
        let timestamp: UInt64
    }
    
    struct Contract: Codable {
        let parameter: Parameter
        let type: String
    }
    
    struct Parameter: Codable {
        let value: Value
        let type_url: String
    }
    
    struct Value: Codable {
        let amount: UInt64
        let owner_address: String
        let to_address: String
    }
    
    let visible: Bool
    let txID: String
    let raw_data: RawData
    let raw_data_hex: String
    var signature: [String]?
}

struct TronBroadcastResponse: Codable {
    let result: Bool
}
