//
//  PolygonTransactionHistoryResult.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 18.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct PolygonTransactionHistoryResult {
    enum Result {
        case description(_ description: String)
        case transactions(_ transactions: [Transaction])
    }

    /// - Note: There are many more fields in this response, but we map only the required ones.
    struct Transaction: Decodable {
        let confirmations: String
        let contractAddress: String?
        let from: String
        let functionName: String?
        let gasPrice: String
        let gasUsed: String
        let hash: String
        let isError: String?
        let timeStamp: String
        let to: String
        let txreceiptStatus: String?
        let value: String
    }

    let status: String
    let message: String?
    let result: Result
}

// MARK: - Decodable protocol conformance

extension PolygonTransactionHistoryResult: Decodable {
    enum CodingKeys: CodingKey {
        case status
        case message
        case result
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.status = try container.decode(String.self, forKey: .status)
        self.message = try container.decodeIfPresent(String.self, forKey: .message)

        if let description = try? container.decodeIfPresent(String.self, forKey: .result) {
            self.result = .description(description)
        } else {
            let transactions = try container.decode([Transaction].self, forKey: .result)
            self.result = .transactions(transactions)
        }
    }
}
