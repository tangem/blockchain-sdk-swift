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
        case .address(let address, _):
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
        case .address(_ , let parameters):
            let parameters = try? parameters.asDictionary()
            return .requestParameters(parameters: parameters ?? [:], encoding: URLEncoding.default)
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
        case address(address: String, parameters: AddressRequestParameters)
        case send(tx: Data)
        case txDetails(txHash: String)
        case utxo(address: String)
        case fees(confirmationBlocks: Int)
    }
    
    struct AddressRequestParameters: Encodable {
        /// page: specifies page of returned transactions, starting from 1. If out of range, Blockbook returns the closest possible page.
        let page: Int
        /// pageSize: number of transactions returned by call (default and maximum 1000)
        let pageSize: Int
        let details: [Details]
        
        init(
            page: Int = 1,
            pageSize: Int = 1000,
            details: [BlockBookTarget.AddressRequestParameters.Details] = [.txs]
        ) {
            self.page = page
            self.pageSize = pageSize
            self.details = details
        }
        
        enum Details: String, Encodable {
            /// basic: return only address balances, without any transactions
            case basic
            /// tokens: basic + tokens belonging to the address (applicable only to some coins)
            case tokens
            /// tokenBalances: basic + tokens with balances + belonging to the address (applicable only to some coins)
            case tokenBalances
            /// txids: tokenBalances + list of txids, subject to from, to filter and paging
            case txids
            /// txslight: tokenBalances + list of transaction with limited details (only data from index), subject to from, to filter and paging
            case txslight
            /// txs: tokenBalances + list of transaction with details, subject to from, to filter and paging
            case txs
        }
        
        enum CodingKeys: CodingKey {
            case page
            case pageSize
            case details
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: BlockBookTarget.AddressRequestParameters.CodingKeys.self)
            try container.encode(self.page, forKey: BlockBookTarget.AddressRequestParameters.CodingKeys.page)
            try container.encode(self.pageSize, forKey: BlockBookTarget.AddressRequestParameters.CodingKeys.pageSize)
            try container.encode(
                self.details.map { $0.rawValue }.joined(separator: ","),
                forKey: BlockBookTarget.AddressRequestParameters.CodingKeys.details
            )
        }
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
