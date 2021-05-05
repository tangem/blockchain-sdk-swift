//
//  EthereumTarget.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 18.12.2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import Moya

enum EthereumTarget: TargetType {
    static let infuraTokenId = 03
    static let coinId = 67
    
    case balance(address: String, network: EthereumNetwork)
    case transactions(address: String, network: EthereumNetwork)
    case pending(address: String, network: EthereumNetwork)
    case send(transaction: String, network: EthereumNetwork)
    case tokenBalance(address: String, contractAddress: String, network: EthereumNetwork)
    case gasLimit(to: String, from: String, data: String?, network: EthereumNetwork)
    case gasPrice(network: EthereumNetwork)
    
    var baseURL: URL {
        switch self {
        case .balance(_, let network): return network.url
        case .pending(_, let network): return network.url
        case .send(_, let network): return network.url
        case .tokenBalance(_, _, let network): return network.url
        case .transactions(_, let network): return network.url
        case .gasLimit(_, _, _, let network): return network.url
        case .gasPrice(let network): return network.url
        }
    }
    
    var path: String {
        return ""
    }
    
    var method: Moya.Method {
        return .post
    }
    
    var sampleData: Data { Data() }
    
    var task: Task {
        var parameters: [String: Any] = [
            "jsonrpc": "2.0",
            "method": ethMethod,
            "id": EthereumTarget.coinId
        ]
        
        var params: [Any] = []
        switch self {
        case .balance(let address, _), .transactions(let address, _), .pending(let address, _):
            params.append(address)
        case .send(let transaction, _):
            params.append(transaction)
        case .tokenBalance(let address, let contractAddress, _):
            let rawAddress = address.removeHexPrefix()
            let dataValue = ["data": "0x70a08231000000000000000000000000\(rawAddress)", "to": contractAddress]
            params.append(dataValue)
        case .gasLimit(let to, let from, let data, network: _):
            var gasLimitParams = [String: String]()
            gasLimitParams["from"] = from
            gasLimitParams["to"] = to
            if let data = data {
                gasLimitParams["data"] = data
            }
            params.append(gasLimitParams)
        case .gasPrice:
            break
        }
        
        if let blockParams = blockParams {
            params.append(blockParams)
        }
        parameters["params"] = params
        
        return .requestParameters(parameters: parameters, encoding: JSONEncoding.default)
    }
    
    var headers: [String : String]? {
        return ["Content-Type": "application/json"]
    }
    
    private var ethMethod: String {
        switch self {
        case .balance: return "eth_getBalance"
        case .transactions, .pending: return "eth_getTransactionCount"
        case .send: return "eth_sendRawTransaction"
        case .tokenBalance: return "eth_call"
        case .gasLimit: return "eth_estimateGas"
        case .gasPrice: return "eth_gasPrice"
        }
    }
    
    private var blockParams: String? {
        switch self {
        case .balance, .transactions, .tokenBalance: return "latest"
        case .pending: return "pending"
        case .send, .gasLimit, .gasPrice: return nil
        }
    }
}
