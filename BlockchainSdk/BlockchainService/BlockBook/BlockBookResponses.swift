//
//  BlockBookResponses.swift
//  BlockchainSdk
//
//  Created by Pavel Grechikhin on 20.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

struct BlockBookAddressResponse: Decodable {
    let page: Int
    let totalPages: Int
    let itemsOnPage: Int
    let address: String
    let balance: String
    let totalReceived: String
    let totalSent: String
    let unconfirmedBalance: String
    let unconfirmedTxs: Int
    let txs: Int
    let transactions: [Transaction]?
    
    struct Transaction: Decodable {
        let txid: String
        let version: Int
        let vin: [Vin]
        let vout: [Vout]
        let blockHash: String
        let blockHeight: Int
        let confirmations: Int
        let blockTime: Int
        let size: Int
        let vsize: Int
        let value: String
        let valueIn: String
        let fees: String
        let hex: String
    }
    
    struct Vin: Decodable {
        let txid: String
        let sequence: Int?
        let n: Int
        let addresses: [String]
        let isAddress: Bool
        let value: String?
        let hex: String?
        let vout: Int?
        let isOwn: Bool?
    }
    
    struct Vout: Codable {
        let value: String
        let n: Int
        let hex: String
        let addresses: [String]
        let isAddress: Bool
        let spent: Bool?
        let isOwn: Bool?
    }
}

struct BlockBookUnspentTxResponse: Decodable {
    let txid: String
    let vout: Int
    let value: String
    let confirmations: Int
    let lockTime: Int?
    let height: Int?
    let coinbase: Bool?
    let scriptPubKey: String?
}

struct BlockBookFeeResponse: Decodable {
    struct Result: Decodable {
        let feerate: Double
    }
    
    let result: Result
}
