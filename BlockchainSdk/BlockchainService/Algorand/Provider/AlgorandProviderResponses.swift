//
//  AlgorandResponses.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 10.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct AlgorandErrorResponse: Error {
    let message: String
}

enum AlgorandResponse {
    struct Account: Decodable {
        let address: String
        let amount: UInt64
        let pendingRewards: UInt64?
        let rewardBase: UInt64?
        let minBalance: UInt64
        let round: UInt64
        let status: String

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            address = try container.decode(String.self, forKey: .address)
            amount = try container.decode(UInt64.self, forKey: .amount)
            minBalance = try container.decode(UInt64.self, forKey: .minBalance)
            pendingRewards = try container.decodeIfPresent(UInt64.self, forKey: .pendingRewards)
            rewardBase = try container.decodeIfPresent(UInt64.self, forKey: .rewardBase)
            round = try container.decode(UInt64.self, forKey: .round)
            status = try container.decode(String.self, forKey: .status)
        }

        private enum CodingKeys: String, CodingKey {
            case address = "address"
            case amount = "amount"
            case createdApps = "apps-local-state"
            case appsLocalState = "apps-total-schema"
            case assets = "assets"
            case pendingRewards
            case rewardBase
            case minBalance = "min-balance"
            case round
            case status
            case totalAppsOptedin
            case totalAssetsOptedin
        }
    }
    
    struct TransactionParams: Decodable {
        var genesisId: String
        var genesisHash: String
        var consensusVersion: String
        var fee: UInt64
        var lastRound: UInt64
        var minFee: UInt64
    }
}

