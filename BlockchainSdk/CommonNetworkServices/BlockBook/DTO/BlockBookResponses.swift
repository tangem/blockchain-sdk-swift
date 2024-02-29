//
//  BlockBookResponses.swift
//  BlockchainSdk
//
//  Created by Pavel Grechikhin on 20.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

struct BlockBookAddressResponse: Decodable {
    let page: Int?
    let totalPages: Int?
    let itemsOnPage: Int?
    let address: String
    let balance: String
    let unconfirmedBalance: String
    let unconfirmedTxs: Int
    /// All transactions count
    let txs: Int
    /// Only for EVM-like. Main network transactions count
    let nonTokenTxs: Int?
    let transactions: [Transaction]?
    let tokens: [Token]?
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
        /// - Warning: For some blockchains (e.g. Ethereum POW) the contract address is stored
        /// in the `token` field instead of the `contract` field of the response.
        let contract: String?
        let token: String?
        let name: String?
        let symbol: String?
        let decimals: Int
        let value: String?
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


struct SendResponse: Decodable {
    let result: String
}

struct NodeEstimateFeeResponse: Decodable {
    let result: Decimal
    let id: String
}
