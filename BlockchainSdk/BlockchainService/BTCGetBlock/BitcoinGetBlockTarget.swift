//
//  BTCGetBlockTarget.swift
//  BlockchainSdk
//
//  Created by Pavel Grechikhin on 20.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Moya

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
    let id: String = "getblock.io"
    let method: String = "estimatesmartfee"
    let params: [Param] = [.integer(1), .stringArray(["default"])]
}

fileprivate struct BTCSendTxParameters: Encodable {
    let hexstring: String
    let maxfeerate: String = "0"
}

struct BitcoinGetBlockTarget: TargetType {
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
        return URL(string: "https://btc.getblock.io/mainnet/")!
    }
    
    var path: String {
        switch endpoint {
        case .address(let walletAddress):
            return "api/v2/address/\(walletAddress)"
        case .txDetails(let txHash):
            return "api/v2/tx/\(txHash)"
        case .txUnspents(let walletAddress):
            return "api/v2/utxo/\(walletAddress)"
        case .fees, .send:
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
        case .txDetails, .address, .txUnspents:
            return .requestPlain
        case .send(let txHex):
            let body = try! JSONEncoder().encode(BTCSendTxParameters(hexstring: txHex))
            return .requestCompositeData(bodyData: body, urlParameters: [:])
        case .fees:
            let body = try! JSONEncoder().encode(BTCFeeParameters())
            return .requestCompositeData(bodyData: body, urlParameters: [:])
        }
    }
    
    var headers: [String : String]? {
        switch endpoint {
        case .send, .address, .txDetails, .txUnspents:
            return ["x-api-key": apiKey]
        default:
            return ["Content-Type": "application/json"]
        }
    }
}
