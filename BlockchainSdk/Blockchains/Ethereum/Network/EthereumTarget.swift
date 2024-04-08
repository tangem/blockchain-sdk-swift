//
//  EthereumTarget.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 18.12.2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import Moya

struct EthereumTarget: TargetType {
    let targetType: EthereumTargetType
    let baseURL: URL
    
    var path: String {
        return ""
    }
    
    var method: Moya.Method {
        return .post
    }
    
    var task: Task {
        return .requestJSONEncodable(jsonRpcRequest)
    }
    
    var headers: [String : String]? {
        [
            "Content-Type": "application/json",
        ]
    }
}

private extension EthereumTarget {
    static var id: Int = 0

    var jsonRpcRequest: Encodable {
        EthereumTarget.id += 1

        switch targetType {
        case .balance(let address):
            return JSONRPC.Request(id: EthereumTarget.id, method: "eth_getBalance", params: [address, "latest"])
        case .transactions(let address):
            return JSONRPC.Request(id: EthereumTarget.id, method: "eth_getTransactionCount", params: [address, "latest"])
        case .pending(let address):
            return JSONRPC.Request(id: EthereumTarget.id, method: "eth_getTransactionCount", params: [address, "pending"])
        case .send(let transaction):
            return JSONRPC.Request(id: EthereumTarget.id, method: "eth_sendRawTransaction", params: [transaction])
        case .gasLimit(let params):
            return JSONRPC.Request(id: EthereumTarget.id, method: "eth_estimateGas", params: params)
        case .gasPrice:
            return JSONRPC.Request(id: EthereumTarget.id, method: "eth_gasPrice", params: [String]()) // Empty params
        case .priorityFee:
            return JSONRPC.Request(id: EthereumTarget.id, method: "eth_maxPriorityFeePerGas", params: [String]()) // Empty params
        case .call(let params):
            return JSONRPC.Request(id: EthereumTarget.id, method: "eth_call", params: params)
        case .feeHistory:
            let blocks: Int = 4
            let block = "latest"
            let percentile: [Int] = [25, 75]
            let params: [AnyEncodable] = [AnyEncodable(blocks), AnyEncodable(block), AnyEncodable(percentile)]

            return JSONRPC.Request(id: EthereumTarget.id, method: "eth_feeHistory", params: params)
        }
    }
}

extension EthereumTarget {
    enum EthereumTargetType {
        case balance(address: String)
        case transactions(address: String)
        case pending(address: String)
        case send(transaction: String)
        case gasLimit(params: GasLimitParams)
        case gasPrice
        case call(params: CallParams)
        case priorityFee

        /// https://www.quicknode.com/docs/ethereum/eth_feeHistory
        case feeHistory
    }
}
