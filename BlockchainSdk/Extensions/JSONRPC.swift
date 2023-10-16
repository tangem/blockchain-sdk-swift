//
//  JSONRPC.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 13.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
//import AnyCodable

// MARK: - Request

struct JSONRPCParams<T>: Encodable where T: Encodable {
    let jsonrpc = JSONRPCProtocolVersion
    let id: String
    let method: String
    let params: T
}

// MARK: - Response

struct JSONRPCResult<T>: Decodable where T: Decodable {
    let jsonrpc: String
    let id: String
    let result: T
}

// MARK: - Private implementation

private let JSONRPCProtocolVersion = "2.0"
