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

struct PolkadotTarget: TargetType {
    enum Target {
        case storage(key: String)
        case blockhash(type: PolkadotBlockhashType)
        case header(hash: String)
        case accountNextIndex(address: String)
        case runtimeVersion(url: URL)
        case queryInfo(extrinsic: String)
        case submitExtrinsic(extrinsic: String)
    }

    let baseURL: URL
    let target: Target
    
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
        switch target {
        case .storage(let key):
            params.append(key)
        case .blockhash(let type):
            switch type {
            case .genesis:
                params.append(0)
            case .latest:
                break
            }
        case .header(let hash):
            params.append(hash)
        case .accountNextIndex(let address):
            params.append(address)
        case .runtimeVersion:
            break
        case .queryInfo(let extrinsic):
            params.append(extrinsic)
        case .submitExtrinsic(let extrinsic):
            params.append(extrinsic)
        }
        
        parameters["params"] = params
        
        return .requestParameters(parameters: parameters, encoding: JSONEncoding.default)
    }
    
    var headers: [String : String]? {
        return ["Content-Type": "application/json"]
    }
    
    var rpcMethod: String {
        switch target {
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
