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
    struct TransactionHistory: Decodable {
        let nextToken: String?
        let currentRound: Int
        let transactions: [TransactionHistoryItem]
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            nextToken = try container.decode(String.self, forKey: .nextToken)
            currentRound = try container.decode(Int.self, forKey: .currentRound)
            transactions = try container.decode([TransactionHistoryItem].self, forKey: .transactions)
        }

        private enum CodingKeys: String, CodingKey {
            case nextToken = "next-token"
            case currentRound = "current-round"
            case transactions
        }
    }
    
    struct TransactionHistoryItem: Decodable {
        
    }
}
