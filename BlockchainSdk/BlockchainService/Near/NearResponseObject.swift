//
//  NearResponseObject.swift
//  BlockchainSdk
//
//  Created by Pavel Grechikhin on 09.06.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

struct NearGasPriceResponse: Decodable {
    let jsonrpc: String
    let id: String
    let result: NearGas
    
    struct NearGas: Decodable {
        let gasPrice: String
    }
}

struct NearAccountInfoResponse: Decodable {
    let jsonrpc: String
    let result: NearResult
    let id: String
    
    struct NearResult: Codable {
        let amount, locked, codeHash: String
        let storageUsage, storagePaidAt, blockHeight: Int
        let blockHash: String
    }
    
    static func convertBalance(from rawBalance: String, countDecimals: Int) -> Decimal {
        let decimals = Int16(countDecimals)
        let handler = NearAccountInfoResponse.makeHandler(with: decimals)
        let balance = NSDecimalNumber(string: rawBalance) ?? NSDecimalNumber(0)
        return balance.dividing(by: NSDecimalNumber(value: 1).multiplying(byPowerOf10: Int16(countDecimals), withBehavior: handler)).decimalValue
    }
    
    private static func makeHandler(with decimals: Int16) -> NSDecimalNumberHandler {
        NSDecimalNumberHandler(roundingMode: .plain, scale: decimals,
                               raiseOnExactness: false,  raiseOnOverflow: false,
                               raiseOnUnderflow: false, raiseOnDivideByZero: false)
    }
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

//MARK: - Access view key list
struct NearAccessKeyListResponse: Decodable {
    static let fullAccessPermission: String = "FullAccess"
    
    let jsonrpc: String
    let result: Result
    let id: String
    
    /// Result
    struct Result: Codable {
        let blockHash: String
        let blockHeight: Int
        let keys: [Key]
        
        /// Keys array
        struct Key: Codable {
            let accessKey: AccessKey
            let publicKey: String
            
            /// Key access description
            struct AccessKey: Codable {
                let nonce: Int
                let permission: String
            }
        }
    }
}
