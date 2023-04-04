//
//  RavencoinTarget.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 03.04.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Moya

struct RavencoinTarget {
    let host: String
    let target: Target
}

extension RavencoinTarget: TargetType {
    enum Target {
        case wallet(address: String)
        case utxo(address: String)
        case transaction(id: String)
        case sendTransaction(raw: RavencoinRawTransactionRequestModel)
    }
    
    var baseURL: URL {
        URL(string: host)!
    }
    
    var path: String {
        switch target {
        case .wallet(let address):
            return "addr/\(address)"
        case .utxo(let address):
            return "addrs/\(address)/utxo"
        case .transaction(let id):
            return "tx/\(id)"
        case .sendTransaction:
            return "tx/send"
        }
    }
    
    var method: Moya.Method {
        switch target {
        case .sendTransaction:
            return .post
        case .wallet, .utxo, .transaction:
            return .get
        }
    }
    
    var task: Moya.Task {
        switch target {
        case .sendTransaction(let raw):
            return .requestJSONEncodable(raw)
        case .wallet, .utxo, .transaction:
            return .requestPlain
        }
    }
    
    // Workaround for API
    var headers: [String : String]? {
        ["User-Agent": "Mozilla/5.0 Version/16.1 Safari/605.1.15"]
    }
}
