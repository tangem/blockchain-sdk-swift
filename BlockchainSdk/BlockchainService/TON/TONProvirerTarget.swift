//
//  TONProvirerTarget.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 26.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Moya

struct TONProvirerTarget: TargetType {
    
    public enum TargetType {
        case estimateFee(boc: String )
        case getBalance(address: String)
        case seqno
    }
    
    // MARK: - Properties
    
    private(set) var host: String
    private(set) var targetType: TargetType
    
    // MARK: - TargetType
    
    var baseURL: URL {
        return URL(string: host)!
    }
    
    var path: String {
        switch targetType {
        case .getBalance:
            return "getAddressBalance"
        case .estimateFee:
            return "estimateFee"
        case .seqno:
            return ""
        }
    }
    
    var method: Moya.Method {
        switch targetType {
        case .getBalance:
            return .get
        case .estimateFee:
            return .post
        case .seqno:
            return .post
        }
    }
    
    var task: Moya.Task {
        var parameters = Dictionary<String, Any>()
        
        switch targetType {
        case .getBalance(let address):
            parameters["address"] = address
        case .estimateFee:
            break
        case .seqno:
            break
        }
        
        return .requestParameters(parameters: parameters, encoding: URLEncoding.default)
    }
    
    var headers: [String : String]? {
        var headers = [
            "Accept": "application/json",
            "Content-Type": "application/json",
            "X-API-KEY": ""
        ]
        
        return headers
    }
    
}
