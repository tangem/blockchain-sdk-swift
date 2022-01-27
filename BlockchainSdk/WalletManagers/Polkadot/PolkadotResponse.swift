//
//  PolkadotResponse.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 27.01.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

struct PolkadotJsonRpcResponse<T: Codable>: Codable {
    let jsonRpc: String
    let id: Int?
    let result: T
    
    private enum CodingKeys: String, CodingKey {
        case jsonRpc = "jsonrpc"
        case id, result
    }
}

struct PolkadotRuntimeVersion: Codable {
    let specName: String
    let specVersion: Int
    let transactionVersion: Int
}
