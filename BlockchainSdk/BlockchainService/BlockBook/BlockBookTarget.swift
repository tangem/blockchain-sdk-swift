//
//  BlockBookTarget.swift
//  BlockchainSdk
//
//  Created by Pavel Grechikhin on 18.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Moya

struct BlockBookTarget: TargetType {
    let request: Request
    let config: BlockBookConfig
    let blockchain: Blockchain
    
    var baseURL: URL {
        URL(string: config.domain(for: request, blockchain: blockchain))!
    }
    
    var path: String {
        let basePath = config.path(for: request)
        
        switch request {
        case .address(let address):
            return basePath + "/address/\(address)"
        case .send:
            return basePath + "/sendtx/"
        case .txDetails(let txHash):
            return basePath + "/tx/\(txHash)"
        case .utxo(let address):
            return basePath + "/utxo/\(address)"
        case .fees:
            return basePath
        }
    }
    
    var method: Moya.Method {
        switch request {
        case .address, .utxo:
            return .get
        case .send, .txDetails, .fees:
            return .post
        }
    }
    
    var task: Moya.Task {
        switch request {
        case .txDetails, .utxo:
            return .requestPlain
        case .send(let tx):
            return .requestData(tx)
        case .fees(let confirmationBlocks):
            return .requestJSONEncodable(BitcoinNodeEstimateSmartFeeParameters(confirmationBlocks: confirmationBlocks))
        case .address:
            return .requestParameters(parameters: ["details": "txs"], encoding: URLEncoding.default)
        }
    }
    
    var headers: [String : String]? {
        [
            "Content-Type": contentType,
            config.apiKeyName: config.apiKeyValue,
        ]
    }
    
    private var contentType: String {
        switch request {
        case .send:
            return "text/plain; charset=utf-8"
        default:
            return "application/json"
        }
    }
}

extension BlockBookTarget {
    enum Request {
        case address(address: String)
        case send(tx: Data)
        case txDetails(txHash: String)
        case utxo(address: String)
        case fees(confirmationBlocks: Int)
    }
}

// Use node API directly, without BlockBook 
fileprivate struct BitcoinNodeEstimateSmartFeeParameters: Encodable {
    let jsonrpc = "2.0"
    let id = "id"
    let method = "estimatesmartfee"
    let params: [Int]
    
    init(confirmationBlocks: Int) {
        self.params = [confirmationBlocks]
    }
}
