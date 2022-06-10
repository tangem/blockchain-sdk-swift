//
//  CryptoAPIsTarget.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 10.06.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Moya

extension CryptoAPIsProvider.Target: TargetType {
    var baseURL: URL { CryptoAPIsProvider.host }
    
    var path: String {
        var path = "blockchain-data"
        path += "/" + coin.path
        path += "/" + coin.network
        
        switch endpoint {
        case let .address(address):
            path += "/addresses"
            path += "/" + address
            return path
            
        case let .unconfirmedTransactions(address):
            path += "/address-transactions-unconfirmed"
            path += "/" + address
            return path
        }
    }
    
    var method: Moya.Method {
        switch endpoint {
        case .address, .unconfirmedTransactions:
            return .get
        }
    }
    
    var task: Task {
        switch endpoint {
        case .address, .unconfirmedTransactions:
            return .requestPlain
        }
        
//        return .requestParameters(parameters: parameters, encoding: URLEncoding.default)
    }
    
    var headers: [String: String]? {
        switch endpoint {
        case .address, .unconfirmedTransactions:
            return [
                "Content-Type": "application/json",
                "X-API-Key": apiKey
            ]
            
//        case .send:
//            return ["Content-Type": "application/x-www-form-urlencoded"]
        }
    }
}
