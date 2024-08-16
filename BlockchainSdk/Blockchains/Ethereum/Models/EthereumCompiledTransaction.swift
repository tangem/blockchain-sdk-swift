//
//  EthereumCompiledTransaction.swift
//  BlockchainSdk
//
//  Created by Dmitry Fedorov on 13.08.2024.
//

import Foundation

struct EthereumCompiledTransaction: Decodable {
    let from: String
    let gasLimit: String
    let to: String
    let data: String
    let nonce: Int
    let type: Int
    let maxFeePerGas: String
    let maxPriorityFeePerGas: String
    let chainId: Int
}
