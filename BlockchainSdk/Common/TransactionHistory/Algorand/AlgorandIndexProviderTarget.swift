//
//  AlgorandIndexProviderTarget.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 22.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Moya

struct AlgorandIndexProviderTarget: TargetType {
    // MARK: - Properties
    
    private let node: NodeInfo
    private let targetType: TargetType
    
    // MARK: - Init
    
    init(node: NodeInfo, targetType: TargetType) {
        self.node = node
        self.targetType = targetType
    }
    
    var baseURL: URL {
        return node.url
    }

    var path: String {
        switch targetType {
        case .getTransactions:
            return "v2/transactions"
        }
    }
    
    var method: Moya.Method {
        switch targetType {
        case .getTransactions:
            return .get
        }
    }
    
    var task: Moya.Task {
        switch targetType {
        case .getTransactions(let address, let limit, let next):
            let parameters: [String: Any?] = [
                "address": address,
                "limit": limit,
                "next": next
            ]
            
            return .requestParameters(
                parameters: parameters.compactMapValues({$0}),
                encoding: URLEncoding.default
            )
        }
    }
    
    var headers: [String : String]? {
        var headers: [String : String] = [
            "Accept": "application/json"
        ]
        
        if let apiKeyInfo = node.keyInfo {
            headers[apiKeyInfo.headerName] = apiKeyInfo.headerValue
        }
        
        return headers
    }
}

extension AlgorandIndexProviderTarget {
    enum TargetType {
        case getTransactions(address: String, limit: Int?, next: String?)
    }
}
