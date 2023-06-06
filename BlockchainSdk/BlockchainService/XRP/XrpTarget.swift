//
//  XrpTarget.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 09.04.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Moya

enum XrpUrl {
    case xrpLedgerFoundation
    case nowNodes(apiKey: String)
    case getBlock(apiKey: String)
    
    var url: URL {
        switch self {
        case .xrpLedgerFoundation:
            return URL(string: "https://xrplcluster.com/")!
        case .nowNodes:
            return URL(string: "https://xrp.nownodes.io")!
        case .getBlock:
            return URL(string: "https://xrp.getblock.io/mainnet")!
        }
    }

    var apiKeyHeaderValue: String? {
        switch self {
        case .nowNodes(let apiKey):
            return apiKey
        case .getBlock(let apiKey):
            return apiKey
        default:
            return nil
        }
    }

    var apiKeyHeaderName: String? {
        switch self {
        case .nowNodes:
            return Constants.nowNodesApiKeyHeaderName
        case .getBlock:
            return Constants.xApiKeyHeaderName
        default:
            return nil
        }
    }
}

enum XrpTarget: TargetType {
    case accountInfo(account:String, url: XrpUrl)
    case unconfirmed(account:String, url: XrpUrl)
    case submit(tx:String, url: XrpUrl)
    case fee(url: XrpUrl)
    case reserve(url: XrpUrl)
    
    var baseURL: URL {
        xrpURL.url
    }

    var xrpURL: XrpUrl {
        switch self {
        case .accountInfo(_, let url):
            return url
        case .fee(let url):
            return url
        case .reserve(let url):
            return url
        case .submit(_, let url):
            return url
        case .unconfirmed(_, let url):
            return url
        }
    }
    
    var path: String {""}
    
    var method: Moya.Method { .post }
    
    var sampleData: Data { return Data() }
    
    var task: Task {
        switch self {
        case .accountInfo(let account, _):
            let parameters: [String: Any] = [
                "method" : "account_info",
                "params": [
                    [
                        "account" : account,
                        "ledger_index" : "validated"
                    ]
                ]
            ]
            return .requestParameters(parameters: parameters, encoding: JSONEncoding.default)
        case .unconfirmed(let account, _):
            let parameters: [String: Any] = [
                "method" : "account_info",
                "params": [
                    [
                        "account" : account,
                        "ledger_index" : "current"
                    ]
                ]
            ]
            return .requestParameters(parameters: parameters, encoding: JSONEncoding.default)
        case .submit(let tx, _):
            let parameters: [String: Any] = [
                "method" : "submit",
                "params": [
                    [
                        "tx_blob": tx
                    ]
                ]
            ]
            return .requestParameters(parameters: parameters, encoding: JSONEncoding.default)
        case .fee:
            let parameters: [String: Any] = [
                "method" : "fee"
            ]
            return .requestParameters(parameters: parameters, encoding: JSONEncoding.default)
        case .reserve:
            let parameters: [String: Any] = [
                "method" : "server_state"
            ]
            return .requestParameters(parameters: parameters, encoding: JSONEncoding.default)
        }
    }
    
    public var headers: [String: String]? {
        var headers = ["Content-Type": "application/json"]

        if let apiKeyHeaderName = xrpURL.apiKeyHeaderName,
           let apiKeyHeaderValue = xrpURL.apiKeyHeaderValue {
            headers[apiKeyHeaderName] = apiKeyHeaderValue
        }

        return headers
    }
}
