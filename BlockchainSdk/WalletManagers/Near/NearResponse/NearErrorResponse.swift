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
    let blockHash: String?
    let blockHeight: Int?
    let requestedAccountId: String?
    let errorMessage: String?
}

//MARK: - Account history

struct NearAccountHistoryResponse: Decodable {
    let jsonrpc: String
    let result: Result
    let id: String
    
    struct Result: Decodable {
        let blockHash: String
        let changes: [NearAccountHistoryChangeElementResponse]
    }
}

struct NearAccountHistoryChangeElementResponse: Decodable {
    let cause: Cause
    let type: String
    let change: NearHistoryChangeResponse
    
    struct Cause: Decodable {
        let type: String
        let txHash, receiptHash: String?
    }
}

struct NearHistoryChangeResponse: Decodable {
    let accountId, amount, locked, codeHash: String
    let storageUsage, storagePaidAt: Int
}

