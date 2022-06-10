//
//  CryptoAPIsTarget.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 10.06.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Moya

enum CryptoAPIsCoinType {
    case dash
    
    var path: String {
        switch self {
        case .dash: return "dash"
        }
    }
    
    var network: String {
        /// CryptoAPIs uses only for testnet
        return "testnet"
    }
}

struct CryptoAPIsTarget {
    static let host = URL(string: "https://rest.cryptoapis.io/v2/")!
    
    enum Target {
        case address(address: String, coin: CryptoAPIsCoinType)
    }
    
    let apiKey: String
    let target: Target
    
    
    init(apiKey: String, target: Target) {
        self.apiKey = apiKey
        self.target = target
    }
}
 
extension CryptoAPIsTarget: TargetType {
    var baseURL: URL { CryptoAPIsTarget.host }
    
    var path: String {
        switch target {
        case let .address(address, coin):
            var endpoint = "blockchain-data"
            endpoint += "/" + coin.path
            endpoint += "/" + coin.network
            endpoint += "/addresses"
            endpoint += "/" + address
            return endpoint
        }
    }
    
    var method: Moya.Method {
        switch target {
        case .address:
            return .get
        }
    }
    
    var sampleData: Data {
        return Data()
    }
    
    var task: Task {
        switch target {
        case .address:
            return .requestPlain
        }
        
//        return .requestParameters(parameters: parameters, encoding: URLEncoding.default)
    }
    
    var headers: [String: String]? {
        switch target {
        case .address:
            return [
                "Content-Type": "application/json",
                "X-API-Key": apiKey
            ]
            
//        case .send:
//            return ["Content-Type": "application/x-www-form-urlencoded"]
        }
    }
}
