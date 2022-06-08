//
//  NearErrorResponse.swift
//  BlockchainSdk
//
//  Created by Pavel Grechikhin on 06.06.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

struct NearErrorResponse: Decodable, Error {
    let jsonrpc: String
    let id: String
    let error: NearDescriptionError
}

struct NearDescriptionError: Decodable {
    let name: String
    let code: Int
    let message: String
    let data: String
    let cause: NearCauseError
}

struct NearCauseError: Decodable {
    let name: String
    let info: NearInfoError
}

struct NearInfoError: Decodable {
    let blockHash: String
    let blockHeight: Int
    let requestedAccountId: String
    
    enum CodingKeys: String, CodingKey {
        case blockHash = "block_hash"
        case blockHeight = "block_height"
        case requestedAccountId = "requested_account_id"
    }
}
