//
//  JSONRPCParams.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 23.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct JSONRPCParams<T>: Encodable where T: Encodable {
    let jsonrpc = JSONRPC.currentProtocolVersion
    let id: String
    let method: String
    let params: T
}

// MARK: - Private implementation

private enum JSONRPC {
    static let currentProtocolVersion = "2.0"
}
