//
//  EthereumResponse.swift
//  BlockchainSdk
//
//  Created by Andrew Son on 04/05/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

// MARK: - Params

struct GasLimitParams: Encodable {
    let to: String
    let from: String
    let value: String?
    let data: String?
}

struct CallParams: Encodable {
    let to: String
    let data: String
}

// MARK: - Response

/// Final Ethereum response that contain all information about address
struct EthereumInfoResponse {
    let balance: Decimal
    let tokenBalances: [Token: Decimal]
    let txCount: Int
    let pendingTxCount: Int
    var pendingTxs: [PendingTransaction]
}

struct EthereumFeeResponse {
    let gasLimit: BigUInt

    let baseFees: (low: BigUInt, market: BigUInt, fast: BigUInt)
    let priorityFees: (low: BigUInt, market: BigUInt, fast: BigUInt)
}

struct EthereumFeeHistoryResponse: Decodable {
    let baseFeePerGas: [String]
}
