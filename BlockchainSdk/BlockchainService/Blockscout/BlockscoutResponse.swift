//
//  BlockscoutResponse.swift
//  BlockchainSdk
//
//  Created by Andrew Son on 10/02/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct BlockscoutResponse<T: Decodable>: Decodable {
    let message: String
    let status: String
    let result: T
}

struct BlockscoutTransaction: Decodable {
    let blockHash: String
    let blockNumber: String
    let confirmations: String
    let contractAddress: String
    let gas: String
    let gasPrice: String
    let gasUsed: String
    
    let hash: String
    let from: String
    let to: String
    let value: String
    let timeStamp: String
    let nonce: String
    let isError: String
    let transactionIndex: String
}
