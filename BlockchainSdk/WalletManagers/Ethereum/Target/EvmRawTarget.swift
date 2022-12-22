//
//  EVMRawTarget.swift
//  BlockchainSdk
//
//  Created by Pavel Grechikhin on 24.11.2022.
//

import Foundation
import Moya

struct EvmRawTarget: TargetType {
    let apiKeyHeaderName: String?
    let apiKeyHeaderValue: String?
    
    var baseURL: URL
    var parameters: [String: Any]
    
    var task: Moya.Task {
        .requestParameters(parameters: parameters, encoding: JSONEncoding.default)
    }
    
    var path: String = ""
    var method: Moya.Method = .post
    
    var headers: [String : String]? {
        var headers = [
            "Content-Type": "application/json",
        ]
        
        if let apiKeyHeaderName, let apiKeyHeaderValue {
            headers[apiKeyHeaderName] = apiKeyHeaderValue
        }
        
        return headers
    }
}
