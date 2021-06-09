//
//  EthereumAdditionalInfoProvider.swift
//  BlockchainSdk
//
//  Created by Andrew Son on 11/01/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol EthereumAdditionalInfoProvider {
    func getEthTxsInfo(address: String) -> AnyPublisher<EthereumTransactionResponse, Error>
    func getSignatureCount(address: String) -> AnyPublisher<Int, Error>
}

struct EthereumTransactionResponse {
    let balance: Decimal
    let pendingTxs: [PendingTransaction]
}

struct BlockcypherEthereumTransaction: Codable, BlockcypherPendingTxConvertible {
    let blockHeight: Int64
    let hash: String
    let total: UInt64
    let fees: Decimal
    let size: Int
    let gasLimit: UInt64
    let gasUsed: UInt64?
    let gasPrice: UInt64
    let received: Date
    let confirmations: Int
    let inputs: [BlockcypherInput]
    let outputs: [BlockcypherOutput]
}
