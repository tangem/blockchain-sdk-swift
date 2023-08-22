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
    let unconfirmedBalance: String
    let unconfirmedTxs: Int
    /// All transactions count
    let txs: Int
    /// Only for EVM-like. Main network transactions count
    let nonTokenTxs: Int
    let transactions: [Transaction]
    let tokens: [Token]

    enum CodingKeys: String, CodingKey {
        case page
        case totalPages
        case itemsOnPage
        case address
        case balance
        case unconfirmedBalance
        case unconfirmedTxs
        case txs
        case nonTokenTxs
        case transactions
        case tokens
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        page = try values.decode(forKey: .page, default: 0)
        totalPages = try values.decode(forKey: .totalPages, default: 0)
        itemsOnPage = try values.decode(forKey: .itemsOnPage, default: 0)
        address = try values.decode(forKey: .address)
        balance = try values.decode(forKey: .balance)
        unconfirmedBalance = try values.decode(forKey: .unconfirmedBalance)
        unconfirmedTxs = try values.decode(forKey: .unconfirmedTxs)
        txs = try values.decode(forKey: .txs)
        nonTokenTxs = try values.decode(forKey: .nonTokenTxs, default: 0)
        transactions = try values.decode(forKey: .transactions, default: [])
        tokens = try values.decode(forKey: .tokens, default: [])
    }
}

extension BlockBookAddressResponse {
    struct Transaction: Decodable {
        let txid: String
        let version: Int?
        let vin: [Vin]
        let vout: [Vout]
        let blockHash: String?
        let blockHeight: Int
        let confirmations: Int
        let blockTime: Int
        let value: String
        let valueIn: String?
        let fees: String
        let hex: String?
        let tokenTransfers: [TokenTransfer]?
        let ethereumSpecific: EthereumSpecific?
    }
    
    struct Vin: Decodable {
        let txid: String?
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
        let hex: String?
        let addresses: [String]
        let isAddress: Bool
        let spent: Bool?
        let isOwn: Bool?
    }
    
    /// For EVM-like blockchains
    struct TokenTransfer: Decodable {
        let type: String?
        let from: String
        let to: String
        let contract: String
        let name: String?
        let symbol: String?
        let decimals: Int
        let value: String
        
        enum CodingKeys: CodingKey {
            case type
            case from
            case to
            case contract
            case token
            case name
            case symbol
            case decimals
            case value
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            type = try container.decodeIfPresent(forKey: .type)
            from = try container.decode(forKey: .from)
            to = try container.decode(forKey: .to)
            contract = try container.decode(forKey: .contract)
            name = try container.decodeIfPresent(forKey: .name)
            symbol = try container.decodeIfPresent(forKey: .symbol)
            decimals = try container.decode(forKey: .decimals)
            value = try container.decode(forKey: .value, default: "0")
        }
    }
    /// For EVM-like blockchains
    struct EthereumSpecific: Decodable {
        let status: StatusType?
        let nonce: Int?
        let gasLimit: Decimal?
        let gasUsed: Decimal?
        let gasPrice: String?
        let data: String?
        let parsedData : ParsedData?
        
        enum StatusType: Int, Decodable {
            case pending = -1
            case failure = 0
            case ok = 1
        }
        
        struct ParsedData: Decodable {
            /// First 4byte from data. E.g. `0x617ba037`
            let methodId: String
            let name: String
        }
    }
    
    struct Token: Decodable {
        let type: String?
        let name: String?
        let contract: String?
        let transfers: Int?
        let symbol: String?
        let decimals: Int?
        let balance: String?
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
