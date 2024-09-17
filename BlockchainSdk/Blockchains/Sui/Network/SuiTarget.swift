//
// SuiTarget.swift
// BlockchainSdk
//
// Created by Sergei Iakovlev on 30.08.2024
// Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Moya

public struct SuiTarget: TargetType {
    public var baseURL: URL
    public var request: SuiTarget.Request
    
    public var path: String {
        ""
    }
    
    public var method: Moya.Method {
        .post
    }
    
    public var task: Moya.Task {
        .requestJSONRPC(id: request.id, method: request.method, params: request.params)
    }
    
    public var headers: [String : String]?
}


extension SuiTarget {
    public enum Request {
        case getBalance(address: String, coin: String, cursor: String?)
        case getReferenceGasPrice
        case dryRunTransaction(transaction: String)
        case devInspectTransactionBlock(sender: String, transaction: String, gasPrice: String?, epoch: String? = nil)
        case sendTransaction(transaction: String, signature: String)
        
        public var id: Int { 1 }
        
        public var method: String {
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
        
        public var params: (any Encodable)? {
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
