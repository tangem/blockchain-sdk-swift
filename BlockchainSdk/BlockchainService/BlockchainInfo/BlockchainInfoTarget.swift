//
//  BlockchainInfoTarget.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 07.04.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Moya

enum BlockchainInfoTarget: TargetType {
	case address(address: String, offset: Int?)
    case unspents(address: String)
    case send(txHex: String)
    case fees
    case transaction(hash: String)
    
    var baseURL: URL {
        switch self {
        case .fees: return URL(string: "https://api.blockchain.info")!
        default: return URL(string: "https://blockchain.info")!
        }
    }
    
    var path: String {
        switch self {
        case .unspents:
            return "/unspent"
        case .send(_):
            return "/pushtx"
        case .address(let address, _):
            return "/rawaddr/\(address)"
        case .fees:
            return "/mempool/fees"
        case .transaction(let hash):
            return "/rawtx/\(hash)"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .unspents, .fees, .address, .transaction:
            return .get
        case .send:
            return .post
        }
    }
    
    var sampleData: Data {
        return Data()
    }
    
    var task: Task {
        switch self {
        case let .address(_, offset):
			var params = [String:String]()
            params["limit"] = "20"
			if let offset = offset {
				params["offset"] = "\(offset)"
			}
            return .requestParameters(parameters: params, encoding: URLEncoding.default)
        case .unspents(let address):
            return .requestParameters(parameters: ["active": address], encoding: URLEncoding.default)
        case .send(let txHex):
            let params = "tx=\(txHex)"
            let body = params.data(using: .utf8)!
            return .requestData(body)
        case .fees, .transaction:
            return .requestPlain
        }
    }
    
    var headers: [String : String]? {
        switch self {
        case .send:
            return ["Content-Type": "application/x-www-form-urlencoded"]
        default:
            return ["Content-Type": "application/json"]
        }
    }
}
