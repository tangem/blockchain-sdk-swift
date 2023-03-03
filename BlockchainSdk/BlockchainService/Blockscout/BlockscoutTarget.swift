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
    
    case tokenTransfersHistory(address: String, contractAddress: String?)
    
    var baseURL: URL { URL(string: "https://blockscout.bicoccachain.net/api")! }
    
    var path: String { "" }
    
    var method: Moya.Method { .get }
    
    var task: Moya.Task {
        var parameters = [
            "module": "account",
            "action": action
        ]
        
        switch self {
        case .tokenTransfersHistory(let address, let contractAddress):
            parameters["address"] = address
            
            if let contractAddress {
                parameters["contractaddress"] = contractAddress
            }
        }
        
        return .requestParameters(parameters: parameters, encoding: URLEncoding.default)
    }
    
    var headers: [String : String]? { nil }
    
    private var action: String {
        switch self {
        case .tokenTransfersHistory: return "tokentx"
        }
    }
}
