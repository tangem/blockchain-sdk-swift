//
//  AlgorandResponse+TransactionHistory.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 22.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

extension AlgorandResponse {
    /// https://developer.algorand.org/docs/rest-apis/indexer/#get-v2transactions
    enum TransactionHistory {}
}

extension AlgorandResponse.TransactionHistory {
    struct List: Decodable {
        let nextToken: String?
        let currentRound: Int
        let transactions: [Item]
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            nextToken = try container.decode(String.self, forKey: .nextToken)
            currentRound = try container.decode(Int.self, forKey: .currentRound)
            transactions = try container.decode([Item].self, forKey: .transactions)
        }

        private enum CodingKeys: String, CodingKey {
            case nextToken = "next-token"
            case currentRound = "current-round"
            case transactions
        }
    }
    
    struct Item: Decodable {
        let confirmedRound: UInt64
        let fee: UInt64
        let genesisHash: String
        let id: String
        let intraRoundOffset: UInt64
        let paymentTransaction: PaymentTransaction
        let roundTime: UInt64
        let sender: String
        let txType: String
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            confirmedRound = try container.decode(UInt64.self, forKey: .confirmedRound)
            fee = try container.decode(UInt64.self, forKey: .fee)
            genesisHash = try container.decode(String.self, forKey: .genesisHash)
            id = try container.decode(String.self, forKey: .id)
            intraRoundOffset = try container.decode(UInt64.self, forKey: .intraRoundOffset)
            paymentTransaction = try container.decode(PaymentTransaction.self, forKey: .paymentTransaction)
            roundTime = try container.decode(UInt64.self, forKey: .roundTime)
            sender = try container.decode(String.self, forKey: .sender)
            txType = try container.decode(String.self, forKey: .txType)
        }

        private enum CodingKeys: String, CodingKey {
            case confirmedRound = "confirmed-round"
            case fee
            case genesisHash = "genesis-hash"
            case id
            case intraRoundOffset = "intra-round-offset"
            case paymentTransaction = "payment-transaction"
            case roundTime = "round-time"
            case sender
            case txType = "tx-type"
        }
    }
    
    struct PaymentTransaction: Decodable {
        let amount: UInt64
        let closeAmount: UInt64
        let receiver: String
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            amount = try container.decode(UInt64.self, forKey: .amount)
            closeAmount = try container.decode(UInt64.self, forKey: .closeAmount)
            receiver = try container.decode(String.self, forKey: .receiver)
        }

        private enum CodingKeys: String, CodingKey {
            case amount
            case closeAmount = "close-amount"
            case receiver
        }
    }
}
