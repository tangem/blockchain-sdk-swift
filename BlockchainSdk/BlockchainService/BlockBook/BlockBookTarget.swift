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
    enum Request {
        case address(walletAddress: String)
        case send(txHex: String)
        case txDetails(txHash: String)
        case txUnspents(walletAddress: String)
        case fees
    }
    
    let request: Request
    let serviceProvider: BlockBookService
    let blockchain: Blockchain
    let apiKey: String
    var isTestnet: Bool = false
    
    var baseURL: URL {
        URL(string: serviceProvider.domain(for: request, blockchain: blockchain))!
    }
    
    var path: String {
        let basePath = serviceProvider.path(for: request)
        
        switch request {
        case .address(let walletAddress):
            return basePath + "/address/\(walletAddress)"
        case .send(let txHex):
            return basePath + "/sendtx/\(txHex)"
        case .txDetails(let txHash):
            return basePath + "/tx/\(txHash)"
        case .txUnspents(let walletAddress):
            return basePath + "/utxo/\(walletAddress)"
        case .fees:
            return basePath
        }
    }
    
    var method: Moya.Method {
        switch request {
        case .send, .address, .txUnspents:
            return .get
        case .txDetails, .fees:
            return .post
        }
    }
    
    var task: Moya.Task {
        switch request {
        case .txDetails, .send, .txUnspents:
            return .requestPlain
        case .fees:
            return .requestJSONEncodable(BitcoinNodeEstimateSmartFeeParameters())
        case .address:
            return .requestParameters(parameters: ["details": "txs"], encoding: URLEncoding.default)
        }
    }
    
    var headers: [String : String]? {
        [
            Constants.nowNodesApiKeyHeaderName: apiKey,
        ]
    }
}

fileprivate struct BitcoinNodeEstimateSmartFeeParameters: Encodable {
    let jsonrpc = "2.0"
    let id = "nownodes"
    let method = "estimatesmartfee"
    let params = [1000]
}
