//
//  RavencoinTarget.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 16.10.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import Combine

// https://testnet.ravencoin.network/api/addr/mgs9F1oLUAnwLRTJrg2HEVZ4nW3kxWrVns
// https://ravencoin.network/api/addr/RRjP4a6i7e1oX1mZq1rdQpNMHEyDdSQVNi

struct RavencoinTarget {
    let isTestnet: Bool
    let target: RavencoinTargetType
}

// https://api.ravencoin.org/api/tx/send
// https://api.ravencoin.org/api/txs?address=R9evUf3dCSfzdjuRJgvBxAnjA7TPjDYjPo

extension RavencoinTarget: TargetType {
    var headers: [String : String]? {
        /// Hack that api is work
        ["User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)"]
    }

    var baseURL: URL {
        if isTestnet {
            return URL(string: "https://testnet.ravencoin.network/api/")!
        } else {
            /// May be use https://api.ravencoin.org/api/
            return URL(string: "https://ravencoin.network/api/")!
        }
    }
    
    var path: String {
        switch target {
        case let .addressInfo(address):
            return "addr/\(address)"
        case .send:
            return "tx/send"
        case .txs:
            return "txs"
        }
    }
    
    var method: Moya.Method {
        switch target {
        case .addressInfo, .txs:
            return .get
        case .send:
            return .post
        }
    }
    
    var task: Moya.Task {
        switch target {
        case let .txs(address):
            return .requestParameters(parameters: ["address" : address],
                                      encoding: URLEncoding.default)
            
        case .addressInfo:
            return .requestParameters(parameters: ["noTxList" : "1"],
                                      encoding: URLEncoding.default)
        case let .send(tx):
            return .requestCompositeParameters(
                bodyParameters: ["rawtx": tx],
                bodyEncoding: JSONEncoding.default,
                urlParameters: [:]
            )
        }
    }
}

extension RavencoinTarget {
    enum RavencoinTargetType {
        case addressInfo(_ address: String)
        case send(tx: String)
        case txs(_ address: String)
    }
}
