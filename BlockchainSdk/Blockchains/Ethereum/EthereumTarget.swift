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
    static let coinId = 67
    
    let targetType: EthereumTargetType
    let baseURL: URL
    
    var path: String {
        return ""
    }
    
    var method: Moya.Method {
        return .post
    }
    
    var task: Task {
        var parameters: [String: Any] = [
            "jsonrpc": "2.0",
            "method": ethMethod,
            "id": EthereumTarget.coinId
        ]

        var params: [Any] = []
        switch targetType {
        case .balance(let address), .transactions(let address), .pending(let address):
            params.append(address)
        case .send(let transaction):
            params.append(transaction)
        case .gasLimit(let to, let from, let value, let data):
            var gasLimitParams = [String: String]()
            gasLimitParams["from"] = from
            gasLimitParams["to"] = to
            if let value = value {
                gasLimitParams["value"] = value
            }
            if let data = data {
                gasLimitParams["data"] = data
            }
            params.append(gasLimitParams)
        case .gasPrice:
            break
        case .call(let contractAddress, let encodedData):
            let dataValue = ["to": contractAddress, "data": encodedData]
            params.append(dataValue)
        }
        
        if let blockParams = blockParams {
            params.append(blockParams)
        }
        parameters["params"] = params
        
        return .requestParameters(parameters: parameters, encoding: JSONEncoding.default)
    }
    
    var headers: [String : String]? {
        [
            "Content-Type": "application/json",
        ]
    }
    
    private var ethMethod: String {
        switch targetType {
        case .balance: return "eth_getBalance"
        case .transactions, .pending: return "eth_getTransactionCount"
        case .send: return "eth_sendRawTransaction"
        case .call: return "eth_call"
        case .gasLimit: return "eth_estimateGas"
        case .gasPrice: return "eth_gasPrice"
        }
    }
    
    private var blockParams: String? {
        switch targetType {
        case .balance, .transactions, .call: return "latest"
        case .pending: return "pending"
        case .send, .gasLimit, .gasPrice: return nil
        }
    }
}

extension EthereumTarget {
    enum EthereumTargetType {
        case balance(address: String)
        case transactions(address: String)
        case pending(address: String)
        case send(transaction: String)
        case gasLimit(to: String, from: String, value: String?, data: String?)
        case gasPrice
        case call(contractAddress: String, encodedData: String)
    }
}
