//
//  XrpTarget.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 09.04.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Moya

enum XrpUrl: String {
    case xrpLedgerFoundation = "https://xrplcluster.com/"
    case ripple = "https://s1.ripple.com:51234"
    case rippleReserve = "https://s2.ripple.com:51234/"
    
    var url: URL {
        return URL(string: rawValue)!
    }
}

enum XrpTarget: TargetType {
    case accountInfo(account:String, url: XrpUrl)
    case unconfirmed(account:String, url: XrpUrl)
    case submit(tx:String, url: XrpUrl)
    case fee(url: XrpUrl)
    case reserve(url: XrpUrl)
    
    var baseURL: URL {
        switch self {
        case .accountInfo(_, let url):
            return url.url
        case .fee(let url):
            return url.url
        case .reserve(let url):
            return url.url
        case .submit(_, let url):
            return url.url
        case .unconfirmed(_, let url):
            return url.url
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
        return ["Content-Type": "application/json"]
    }
}
