//
//  NEARNetworkParams.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 13.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

enum NEARNetworkParams {
    /// https://docs.near.org/api/rpc/setup#using-finality-param.
    struct Finality: Encodable {
        static var optimistic: Self { Self(value: .optimistic) }
        static var final: Self { Self(value: .final) }

        enum Value: String, Encodable {
            case optimistic
            case final
        }

        let value: Value

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(value.rawValue)
        }
    }

    struct ViewAccount: Encodable {
        enum RequestType: String, Encodable {
            case viewAccount = "view_account"
        }

        let requestType: RequestType
        let finality: Finality
        let accountId: String
    }

    struct ViewAccessKey: Encodable {
        enum RequestType: String, Encodable {
            case viewAccessKey = "view_access_key"
        }

        let requestType: RequestType
        let finality: Finality
        let accountId: String
        /// Expected format is "ed25519:%public_key% (where %public_key% is a Base58 encoded string)".
        let publicKey: String
    }

    /// The payload string has a Base64 encoding.
    typealias Transaction = [String]
}
