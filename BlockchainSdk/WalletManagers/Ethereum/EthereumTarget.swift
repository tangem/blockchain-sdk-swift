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
    
    case balance(address: String, url: URL)
    case transactions(address: String, url: URL)
    case pending(address: String, url: URL)
    case send(transaction: String, url: URL)
    case tokenBalance(address: String, contractAddress: String, url: URL)
    case getAllowance(from: String, to: String, contractAddress: String, url: URL)
    case gasLimit(to: String, from: String, value: String?, data: String?, url: URL)
    case gasPrice(url: URL)
    
    var baseURL: URL {
        switch self {
        case .balance(_, let url): return url
        case .pending(_, let url): return url
        case .send(_, let url): return url
        case .tokenBalance(_, _, let url): return url
        case .getAllowance(_, _, _, let url): return url
        case .transactions(_, let url): return url
        case .gasLimit(_, _, _, _, let url): return url
        case .gasPrice(let url): return url
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
            let rawAddress = address.serialize()
            let dataValue = ["data": "0x70a08231\(rawAddress)", "to": contractAddress]
            params.append(dataValue)
        case .getAllowance(let fromAddress, let toAddress, let contractAddress, _):
            let dataValue = ["data": "0xdd62ed3e\(fromAddress.serialize())\(toAddress.serialize())",
                             "to": contractAddress]
            params.append(dataValue)
        case .gasLimit(let to, let from, let value, let data, _):
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
        case .tokenBalance, .getAllowance: return "eth_call"
        case .gasLimit: return "eth_estimateGas"
        case .gasPrice: return "eth_gasPrice"
        }
    }
    
    private var blockParams: String? {
        switch self {
        case .balance, .transactions, .tokenBalance, .getAllowance: return "latest"
        case .pending: return "pending"
        case .send, .gasLimit, .gasPrice: return nil
        }
    }
}
