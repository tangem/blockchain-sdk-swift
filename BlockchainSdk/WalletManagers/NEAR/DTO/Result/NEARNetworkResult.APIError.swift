//
//  NEARNetworkResult.APIError.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 26.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import struct AnyCodable.AnyDecodable

extension NEARNetworkResult {
    struct APIError: Decodable, Error {
            // There are many more types of errors, but we only care about the ones
            // that can be returned from API endpoints in the 'NEARTarget.swift' file.
        enum ErrorTypeName: Decodable {
            case handlerError
            case requestValidationError
            case internalError
            case unknownError

            init(from decoder: Decoder) throws {
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

            //  There are many more causes of errors, but we only care about the ones
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

            init(from decoder: Decoder) throws {
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
