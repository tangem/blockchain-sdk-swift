//
//  NEARNetworkResult.TransactionSendAwait.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 26.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import struct AnyCodable.AnyDecodable

extension NEARNetworkResult {
    // There are many more fields in this response, but we only
    // care about the hash and status of the transaction.
    struct TransactionSendAwait: Decodable {
        struct TransactionOutcome: Decodable {
            /// Hash of the transaction.
            let id: String
        }

        enum Status: Decodable {
            private enum CodingKeys: String, CodingKey {
                case success = "SuccessValue"
                case failure = "Failure"
            }

            case success
            case failure(AnyDecodable?)

            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)

                if container.contains(.success) {
                    self = .success
                } else {
                    self = .failure(try? container.decodeIfPresent(forKey: .failure))
                }
            }
        }
        
        let transactionOutcome: TransactionOutcome
        let status: Status
    }
}
