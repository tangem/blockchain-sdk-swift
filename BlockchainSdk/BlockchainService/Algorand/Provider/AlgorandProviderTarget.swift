//
//  AlgorandProviderTarget.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 10.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Moya

struct AlgorandProviderTarget: TargetType {
    // MARK: - Properties
    
    private let node: AlgorandProviderNode
    private let targetType: TargetType
    
    // MARK: - Init
    
    init(node: AlgorandProviderNode, targetType: TargetType) {
        self.node = node
        self.targetType = targetType
    }
    
    var baseURL: URL {
        return node.url
    }

    var path: String {
        switch targetType {
        case .getAccounts(let address):
            return "v2/accounts/\(address)"
        case .getTransactionParams:
            return "v2/transactions/params"
        case .transaction:
            return "v2/transactions"
        }
    }
    
    var method: Moya.Method {
        switch targetType {
        case .getAccounts, .getTransactionParams:
            return .get
        case .transaction:
            return .post
        }
    }
    
    var task: Moya.Task {
        switch targetType {
        case .getAccounts, .getTransactionParams:
            return .requestPlain
        case .transaction(let data):
            return .requestData(data)
        }
    }
    
    var headers: [String : String]? {
        var headers: [String : String] = [
            "Accept": "application/json"
        ]
        
        switch self.targetType {
        case .transaction:
            headers["Content-Type"] = "application/x-binary"
        default:
            headers["Content-Type"] = "application/json"
        }
        
        if case .nownodes = node.type, let headerName = node.apiKeyHeaderName {
            headers[headerName] = node.apiKeyValue
        }
        
        return headers
    }
}

extension AlgorandProviderTarget {
    enum TargetType {
        case getAccounts(address: String)
        case getTransactionParams
        case transaction(trx: Data)
    }
}
