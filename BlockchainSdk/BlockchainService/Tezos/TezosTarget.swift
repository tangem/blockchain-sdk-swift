//
//  TezosTarget.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 19.10.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Moya

struct TezosTarget: TargetType {
    let api: TezosApi
    let endpoint: TargetEndpoint
    
    var baseURL: URL {
        return URL(string: api.rawValue)!
    }
    
    var path: String {
        return endpoint.path
    }
    
    var method: Moya.Method {
        return endpoint.method
    }
    
    var sampleData: Data {
        return Data()
    }
    
    var task: Task {
        return endpoint.task
    }
    
    var headers: [String : String]? {
        return ["Content-Type": "application/json"]
    }
    
    
    enum TargetEndpoint {
        case addressData(address: String)
        case getHeader
        case managerKey(address: String)
        case forgeOperations(body: TezosForgeBody)
        case preapplyOperations(body: [TezosPreapplyBody])
        case sendTransaction(tx: String)
        
        var path: String {
            switch self {
            case .addressData(let address):
                return "chains/main/blocks/head/context/contracts/\(address)"
            case .getHeader:
                return "chains/main/blocks/head/header"
            case .managerKey(let address):
                return "chains/main/blocks/head/context/contracts/\(address)/manager_key"
            case .forgeOperations:
                return "chains/main/blocks/head/helpers/forge/operations"
            case .preapplyOperations:
                return "chains/main/blocks/head/helpers/preapply/operations"
            case .sendTransaction:
                return "injection/operation"
            }
        }
        
        var method: Moya.Method {
            switch self {
            case .addressData, .getHeader, .managerKey:
                return .get
            case .forgeOperations, .preapplyOperations, .sendTransaction:
                return .post
            }
        }
        
        var task: Task {
            switch self {
            case .addressData, .getHeader, .managerKey:
                return .requestPlain
            case .forgeOperations(let body):
                return .requestJSONEncodable(body)
            case .preapplyOperations(let body):
                 return .requestJSONEncodable(body)
            case .sendTransaction(let tx):
                return .requestData("\"\(tx)\"".data(using: .utf8)!)
            }
        }
    }

    enum TezosApi: String {
        case tezos = "https://teznode.letzbake.com"
        case tezosReserve = "https://mainnet.tezrpc.me"
    }
}


struct TezosForgeBody: Codable {
    let branch: String
    let contents: [TezosOperationContent]
}

struct TezosOperationContent: Codable {
    let kind: String
    let source: String
    let fee: String
    let counter: String
    let gasLimit: String
    let storageLimit: String
    let publicKey: String?
    let destination: String?
    let amount: String?
    
    enum CodingKeys: String, CodingKey {
        case kind
        case source
        case fee
        case counter
        case gasLimit = "gas_limit"
        case storageLimit = "storage_limit"
        case publicKey = "public_key"
        case destination
        case amount
    }
}

struct TezosPreapplyBody: Codable {
    let `protocol`: String
    let branch: String
    let contents: [TezosOperationContent]
    let signature: String
}
