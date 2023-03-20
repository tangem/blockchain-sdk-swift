//
//  KaspaTarget.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 10.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Moya

struct KaspaTarget: TargetType {
    let request: Request
    let baseURL: URL
    
    var path: String {
        switch request {
        case .blueScore:
            return "/info/virtual-chain-blue-score"
        case .balance(let address):
            return "/addresses/\(address)/balance"
        case .utxos(let address):
            return "/addresses/\(address)/utxos"
        case .transactions:
            return "/transactions"
        case .transaction(let hash):
            return "/transactions/\(hash)"
        }
    }
    
    var method: Moya.Method {
        switch request {
        case .blueScore, .balance, .utxos, .transaction:
            return .get
        case .transactions:
            return .post
        }
    }
    
    var task: Moya.Task {
        switch request {
        case .blueScore, .balance, .utxos, .transaction:
            return .requestPlain
        case .transactions(let transaction):
            return .requestJSONEncodable(transaction)
        }
    }
    
    var headers: [String : String]? {
        nil
    }
}

extension KaspaTarget {
    enum Request {
        case blueScore
        case balance(address: String)
        case utxos(address: String)
        case transactions(transaction: KaspaTransactionRequest)
        case transaction(hash: String)
    }
}
