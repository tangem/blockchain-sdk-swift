//
//  PolkadotTarget.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 27.01.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Moya
enum PolkadotBlockhashType {
    case genesis
    case latest
}

enum PolkadotTarget: TargetType {
    case blockhash(type: PolkadotBlockhashType, network: PolkadotNetwork)
    case header(hash: String, network: PolkadotNetwork)
    case accountNextIndex(address: String, network: PolkadotNetwork)
    case runtimeVersion(network: PolkadotNetwork)
    case submitExtrinsic(extrinsic: String, network: PolkadotNetwork)
    
    var baseURL: URL {
        switch self {
        case .blockhash(_, let network): return network.url
        case .header(_, let network): return network.url
        case .accountNextIndex(_, let network): return network.url
        case .runtimeVersion(let network): return network.url
        case .submitExtrinsic(_, let network): return network.url
        }
    }
    
    var path: String {
        return ""
    }
    
    var method: Moya.Method {
        return .post
    }
    
    var task: Task {
        var parameters: [String: Any] = [
            "id": 1,
            "jsonrpc": "2.0",
            "method": rpcMethod,
        ]
        
        var params: [Any] = []
        switch self {
        case .blockhash(let type, _):
            switch type {
            case .genesis:
                params.append(0)
            case .latest:
                break
            }
        case .header(let hash, _):
            params.append(hash)
        case .accountNextIndex(let address, _):
            params.append(address)
        case .runtimeVersion:
            break
        case .submitExtrinsic(let extrinsic, _):
            params.append(extrinsic)
        }
        
        parameters["params"] = params
        
        return .requestParameters(parameters: parameters, encoding: JSONEncoding.default)
    }
    
    var headers: [String : String]? {
        return ["Content-Type": "application/json"]
    }
    
    var rpcMethod: String {
        switch self {
        case .blockhash:
            return "chain_getBlockHash"
        case .header:
            return "chain_getHeader"
        case .accountNextIndex:
            return "system_accountNextIndex"
        case .runtimeVersion:
            return "state_getRuntimeVersion"
        case .submitExtrinsic:
            return "author_submitExtrinsic"
        }
    }
}
