//
//  NEARNetworkParams.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 13.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

enum NEARNetworkParams {
    enum Finality: String, Encodable {
        /// Uses the latest block recorded on the node that responded to your query
        /// (<1 second delay after the transaction is submitted).
        case optimistic
        /// Uses a block that has been validated on at least 66% of the nodes in the network
        /// (usually takes 2 blocks / approx. 2 second delay).
        case final
    }

    struct ProtocolConfig: Encodable {
        let finality: Finality
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
