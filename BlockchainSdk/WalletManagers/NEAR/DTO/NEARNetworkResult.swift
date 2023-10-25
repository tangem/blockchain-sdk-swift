//
//  NEARNetworkResult.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 13.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import struct AnyCodable.AnyDecodable

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
            let storageAmountPerByte: String
        }

        struct TransactionCosts: Decodable {
            let actionReceiptCreationConfig: CostConfig
            let actionCreationConfig: ActionCreationConfig
        }

        struct AddKeyCost: Decodable {
            let fullAccessCost: CostConfig
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
            let addKeyCost: AddKeyCost
            let transferCost: CostConfig
            let createAccountCost: CostConfig
        }

        let runtimeConfig: RuntimeConfig
    }

    /// Hash of the transaction.
    typealias TransactionSendAsync = String

    // There are much more fields in this response, but we only care about the hash of the transaction.
    struct TransactionSendAwait: Decodable {
        struct TransactionOutcome: Decodable {
            /// Hash of the transaction.
            let id: String
        }

        let transactionOutcome: TransactionOutcome
    }

    struct APIError: Decodable, Error {
        // There are much more error types exists, but we only care about the ones
        // that can be returned from API endpoints in the 'NEARTarget.swift' file.
        enum ErrorTypeName: Decodable {
            case handlerError
            case requestValidationError
            case internalError
            case unknownError

            init(
                from decoder: Decoder
            ) throws {
                let container = try decoder.singleValueContainer()
                let rawValue = try container.decode(String.self)

                switch rawValue {
                case "HANDLER_ERROR":
                    self = .handlerError
                case "REQUEST_VALIDATION_ERROR":
                    self = .requestValidationError
                case "INTERNAL_ERROR":
                    self = .internalError
                default:
                    self = .unknownError
                }
            }
        }

        // There are much more error causes exists, but we only care about the ones
        // that can be returned from API endpoints in the 'NEARTarget.swift' file.
        enum ErrorCauseName: Decodable {
            case unknownBlock
            case invalidAccount
            case unknownAccount
            case unknownAccessKey
            case unavailableShard
            case noSyncedBlocks
            case parseError
            case internalError
            case invalidTransaction
            case timeoutError
            case unknownError

            init(
                from decoder: Decoder
            ) throws {
                let container = try decoder.singleValueContainer()
                let rawValue = try container.decode(String.self)

                switch rawValue {
                case "UNKNOWN_BLOCK":
                    self = .unknownBlock
                case "INVALID_ACCOUNT":
                    self = .invalidAccount
                case "UNKNOWN_ACCOUNT":
                    self = .unknownAccount
                case "UNKNOWN_ACCESS_KEY":
                    self = .unknownAccessKey
                case "UNAVAILABLE_SHARD":
                    self = .unavailableShard
                case "NO_SYNCED_BLOCKS":
                    self = .noSyncedBlocks
                case "PARSE_ERROR":
                    self = .parseError
                case "INTERNAL_ERROR":
                    self = .internalError
                case "INVALID_TRANSACTION":
                    self = .invalidTransaction
                case "TIMEOUT_ERROR":
                    self = .timeoutError
                default:
                    self = .unknownError
                }
            }
        }

        struct ErrorCause: Decodable {
            let name: ErrorCauseName
            let info: AnyDecodable?
        }

        let name: ErrorTypeName
        let cause: ErrorCause
    }
}
