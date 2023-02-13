//
//  BlockscoutTarget.swift
//  BlockchainSdk
//
//  Created by Andrew Son on 10/02/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Moya

enum BlockscoutTarget: TargetType {
    
    case transactionHistory(address: String)
    
    var baseURL: URL { URL(string: "https://blockscout.bicoccachain.net/api")! }
    
    var path: String { "" }
    
    var method: Moya.Method { .get }
    
    var task: Moya.Task {
        var parameters = [String:String]()
        
        switch self {
        case .transactionHistory(let address):
            parameters["module"] = "account"
            parameters["action"] = "txList"
            parameters["address"] = address
        }
        
        return .requestParameters(parameters: parameters, encoding: URLEncoding.default)
    }
    
    var headers: [String : String]? { nil }
    
}
