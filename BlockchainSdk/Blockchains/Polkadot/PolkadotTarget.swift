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
    case storage(key: String, url: URL)
    case blockhash(type: PolkadotBlockhashType, url: URL)
    case header(hash: String, url: URL)
    case accountNextIndex(address: String, url: URL)
    case runtimeVersion(url: URL)
    case queryInfo(extrinsic: String, url: URL)
    case submitExtrinsic(extrinsic: String, url: URL)
    
    var baseURL: URL {
        switch self {
        case .storage(_, let url): return url
        case .blockhash(_, let url): return url
        case .header(_, let url): return url
        case .accountNextIndex(_, let url): return url
        case .runtimeVersion(let url): return url
        case .queryInfo(_, let url): return url
        case .submitExtrinsic(_, let url): return url
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
        case .storage(let key, _):
            params.append(key)
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
        case .queryInfo(let extrinsic, _):
            params.append(extrinsic)
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
        case .storage:
            return "state_getStorage"
        case .blockhash:
            return "chain_getBlockHash"
        case .header:
            return "chain_getHeader"
        case .accountNextIndex:
            return "system_accountNextIndex"
        case .runtimeVersion:
            return "state_getRuntimeVersion"
        case .queryInfo:
            return "payment_queryInfo"
        case .submitExtrinsic:
            return "author_submitExtrinsic"
        }
    }
}
