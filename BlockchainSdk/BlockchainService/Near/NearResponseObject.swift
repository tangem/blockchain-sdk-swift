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
    
    static func convertBalance(from rawBalance: String) -> Decimal {
        let decimals = Int16(24)
        let handler = NearAccountInfoResponse.makeHandler(with: decimals)
        let balance = NSDecimalNumber(string: rawBalance) ?? NSDecimalNumber(0)
        return balance.dividing(by: NSDecimalNumber(value: 1).multiplying(byPowerOf10: Int16(24), withBehavior: handler))
    }
    
    private static func makeHandler(with decimals: Int16) -> NSDecimalNumberHandler {
        NSDecimalNumberHandler(roundingMode: .plain, scale: decimals,
                               raiseOnExactness: false,  raiseOnOverflow: false,
                               raiseOnUnderflow: false, raiseOnDivideByZero: false)
    }
}
