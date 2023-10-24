//
//  NEARNetworkResult.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 13.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

enum NEARNetworkResult {
    struct AccountInfo: Decodable {
        let amount: String
        let blockHash: String
        let blockHeight: UInt
        let codeHash: String
        let locked: String
        let storagePaidAt: UInt
        let storageUsage: UInt
    }

    struct AccessKeyInfo: Decodable {
        // There are 2 types of `AccessKeyPermission` in NEAR currently: `FullAccess` and `FunctionCall`.
        // We only care about `FullAccess` because `Function call` access keys cannot be used to transfer $NEAR.
        enum Permission: Decodable {
            case fullAccess
            case other

            init(
                from decoder: Decoder
            ) throws {
                let container = try decoder.singleValueContainer()
                let rawValue = try container.decode(String.self)

                switch rawValue {
                case "FullAccess":
                    self = .fullAccess
                default:
                    self = .other
                }
            }
        }

        let blockHash: String
        let blockHeight: UInt
        let nonce: UInt
        let permission: Permission
    }

    struct GasPrice: Decodable {
        let gasPrice: String
    }

    // There are much more fields in this response, but we only care about
    // the ones required for the gas price calculation.
    struct ProtocolConfig: Decodable {
        struct RuntimeConfig: Decodable {
            let transactionCosts: TransactionCosts
        }

        struct TransactionCosts: Decodable {
            let actionReceiptCreationConfig: CostConfig
            let actionCreationConfig: ActionCreationConfig
        }

        struct CostConfig: Decodable {
            /// The "sir" here stands for "sender is receiver".
            let sendNotSir: UInt
            /// The "sir" here stands for "sender is receiver".
            let sendSir: UInt
            /// Execution cost is the same for both "sender is receiver" and  "sender is not receiver" cases.
            let execution: UInt
        }

        struct ActionCreationConfig: Decodable {
            let transferCost: CostConfig
        }

        let runtimeConfig: RuntimeConfig
    }

    /// Hash of the transaction.
    typealias TransactionSendAsync = String

    // There are much more fields in this response, but we only care about
    // the hash of the transaction, the last block hash, and the last nonce.
    struct TransactionSendAwait: Decodable {
        struct Transaction: Decodable {
            /// Hash of the transaction.
            let hash: String
            let nonce: UInt
        }

        struct TransactionOutcome: Decodable {
            /// Hash of the transaction.
            let id: String
            let blockHash: String
        }

        let transaction: Transaction
        let transactionOutcome: TransactionOutcome
    }
}
