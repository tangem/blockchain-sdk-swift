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
    let result: Result
    let id: String
    
    struct Result: Codable {
        let amount, locked, codeHash: String
        let storageUsage, storagePaidAt, blockHeight: Int
        let blockHash: String
    }
}
