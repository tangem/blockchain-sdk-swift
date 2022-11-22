//
//  NowNodesBTCTarget.swift
//  BlockchainSdk
//
//  Created by Pavel Grechikhin on 18.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Moya

struct BitcoinNowNodesTarget: TargetType {
    enum Endpoint {
        case address(walletAddress: String)
        case send(txHex: String)
        case txDetails(txHash: String)
        case txUnspents(walletAddress: String)
        case fees
    }
    
    let endpoint: Endpoint
    let apiKey: String
    
    var baseURL: URL {
        switch endpoint {
        case .fees:
            return URL(string: "https://api.blockchain.info")!
        default:
            return URL(string: "https://btcbook.nownodes.io/")!
        }
    }
    
    var path: String {
        switch endpoint {
        case .address(let walletAddress):
            return "api/v2/address/\(walletAddress)"
        case .send(let txHex):
            return "api/v2/sendtx/\(txHex)"
        case .txDetails(let txHash):
            return "api/v2/tx/\(txHash)"
        case .txUnspents(let walletAddress):
            return "api/v2/utxo/\(walletAddress)"
        case .fees:
            return ""
        }
    }
    
    var method: Moya.Method {
        switch endpoint {
        case .send, .address, .txUnspents:
            return .get
        case .txDetails, .fees:
            return .post
        }
    }
    
    var task: Moya.Task {
        switch endpoint {
        case .txDetails, .send, .txUnspents:
            return .requestPlain
        case .fees:
            let body = try! JSONEncoder().encode(BTCFeeParameters())
            return .requestCompositeData(bodyData: body, urlParameters: [:])
        case .address(let walletAddress):
            return .requestParameters(parameters: ["details": "txs"], encoding: URLEncoding.default)
        }
    }
    
    var headers: [String : String]? {
        switch endpoint {
        case .send, .address, .txDetails, .txUnspents:
            return ["api-key": apiKey]
        default:
            return ["Content-Type": "application/json"]
        }
    }
}

fileprivate struct BTCFeeParameters: Encodable {
    enum Param: Encodable {
        case integer(Int)
        case stringArray([String])

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .integer(let x):
                try container.encode(x)
            case .stringArray(let x):
                try container.encode(x)
            }
        }
    }
    
    let jsonrpc = "2.0"
    let id: String = "nownodes"
    let method: String = "getblockstats"
    let params: [Param] = [.integer(1000), .stringArray(["minfeerate", "avgfeerate"])]
}
