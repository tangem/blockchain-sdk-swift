//
//  JSONRPCResult.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 23.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct JSONRPCResult<T>: Decodable where T: Decodable {
    let jsonrpc: String
    let id: String
    let result: T
}
