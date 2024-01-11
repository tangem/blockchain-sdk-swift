//
//  AlgorandResponses.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 10.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct AlgorandErrorResponse: Error, Decodable {
    let message: String
}

enum AlgorandResponse {
    enum AccountStatus: String, Decodable {
        case Offline, Online, NotParticipating
    }
    
    /// https://developer.algorand.org/docs/rest-apis/algod/#account
    struct Account: Decodable {
        let address: String
        let amount: UInt64
        let minBalance: UInt64
        let round: UInt64
        
        /*
         [onl] delegation status of the account's MicroAlgos
         * Offline - indicates that the associated account is delegated.
         * Online - indicates that the associated account used as part of the delegation pool.
         * NotParticipating - indicates that the associated account is neither a delegator nor a delegate.
         */
        let status: AccountStatus

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            address = try container.decode(String.self, forKey: .address)
            amount = try container.decode(UInt64.self, forKey: .amount)
            minBalance = try container.decode(UInt64.self, forKey: .minBalance)
            round = try container.decode(UInt64.self, forKey: .round)
            status = try container.decode(AccountStatus.self, forKey: .status)
        }

        private enum CodingKeys: String, CodingKey {
            case address = "address"
            case amount = "amount"
            case minBalance = "min-balance"
            case round
            case status
        }
    }
    
    /// https://developer.algorand.org/docs/rest-apis/algod/#get-v2transactionsparams
    struct TransactionParams: Decodable {
        var genesisId: String
        var genesisHash: String
        var consensusVersion: String
        var fee: UInt64
        var lastRound: UInt64
        var minFee: UInt64
    }
}

