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
    let result: T?
    let error: PolkadotJsonRpcError?
    
    private enum CodingKeys: String, CodingKey {
        case jsonRpc = "jsonrpc"
        case id, result, error
    }
}

struct PolkadotJsonRpcError: Codable {
    let code: Int?
    let message: String?
    
    var error: Error {
        NSError(domain: message ?? .unknown, code: code ?? -1, userInfo: nil)
    }
}

struct PolkadotHeader: Codable {
    let number: String
}

struct PolkadotRuntimeVersion: Codable {
    let specName: String
    let specVersion: Int
    let transactionVersion: Int
}
