//
//  EVMRawTarget.swift
//  BlockchainSdk
//
//  Created by Pavel Grechikhin on 24.11.2022.
//

import Foundation
import Moya

struct EvmRawTarget: TargetType {
    let apiKey: String?
    
    var baseURL: URL
    var parameters: [String: Any]
    
    var task: Moya.Task {
        .requestParameters(parameters: parameters, encoding: JSONEncoding.default)
    }
    
    var path: String = ""
    var method: Moya.Method = .post
    
    var headers: [String : String]? {
        guard let apiKey else { return ["Content-Type": "application/json"] }
        
        return baseURL.absoluteString.contains("getblock.io") ? ["x-api-key": apiKey, "Content-Type": "application/json"] : ["Content-Type": "application/json"]
    }
}
