//
//  RavencoinTarget.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 03.04.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Moya

enum RavencoinTarget: TargetType {
    case wallet(address: String)
    case utxo(address: String)
    case transaction(id: String)
    case sendTransaction(raw: RavencoinRawTransactionRequestModel)
    
    var baseURL: URL {
        URL(string: "https://ravencoin.network/api")!
    }
    
    var path: String {
        switch self {
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
    
    var method: Moya.Method { .get }
    
    var task: Moya.Task { .requestPlain }
    
    // Workaround for API
    var headers: [String : String]? {
        ["User-Agent": "Mozilla/5.0 Version/16.1 Safari/605.1.15"]
    }
}
