//
// SuiTarget.swift
// BlockchainSdk
//
// Created by Sergei Iakovlev on 30.08.2024
// Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Moya

struct SuiTarget: TargetType {
    let baseURL: URL
    let request: SuiTarget.Request
    
    var path: String {
        ""
    }
    
    var method: Moya.Method {
        .post
    }
    
    var task: Moya.Task {
        .requestJSONRPC(id: request.id, method: request.method, params: request.params)
    }
    
    var headers: [String : String]?
}


extension SuiTarget {
    enum Request {
        case getBalance(address: String, coin: String, cursor: String?)
        case getReferenceGasPrice
        case dryRunTransaction(transaction: String)
        case devInspectTransactionBlock(sender: String, transaction: String, gasPrice: String?, epoch: String? = nil)
        case sendTransaction(transaction: String, signature: String)
        
        var id: Int { 1 }
        
        var method: String {
            switch self {
            case .getBalance:
                return "suix_getCoins"
            case .getReferenceGasPrice:
                return "suix_getReferenceGasPrice"
            case .dryRunTransaction:
                return "sui_dryRunTransactionBlock"
            case .devInspectTransactionBlock:
                return "sui_devInspectTransactionBlock"
            case .sendTransaction:
                return "sui_executeTransactionBlock"
            }
        }
        
        var params: (any Encodable)? {
            switch self {
            case .getBalance(let address, let coin, let cursor):
                return [address, coin, cursor]
            case .getReferenceGasPrice:
                return nil
            case .devInspectTransactionBlock(sender: let sender, transaction: let transaction, gasPrice: let gasPrice, epoch: let epoch):
                return [AnyEncodable(sender), AnyEncodable(transaction), AnyEncodable(gasPrice), AnyEncodable(epoch), AnyEncodable(["skip_checks": true])]
            case .dryRunTransaction(let transaction):
                return [transaction]
            case .sendTransaction(let transaction, let signature):
                return [AnyEncodable(transaction), AnyEncodable([signature])]
            }
        }
    }
}
