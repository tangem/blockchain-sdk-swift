//
//  BlockchairTarget.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 14.02.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Moya

enum BlockchairEndpoint {
    case bitcoin(testnet: Bool),
         bitcoinCash,
         litecoin,
         dogecoin,
         ethereum(testnet: Bool)
    
    var path: String {
        switch self {
        case .bitcoin(let testnet): return "bitcoin" + (testnet ? "/testnet" : "")
        case .bitcoinCash: return "bitcoin-cash"
        case .litecoin: return "litecoin"
        case .dogecoin: return "dogecoin"
        case .ethereum(let testnet): return "ethereum" + (testnet ? "/testnet" : "")
        }
    }
    
    var blockchain: Blockchain {
        switch self {
        case .bitcoin(let testnet):
            return .bitcoin(testnet: testnet)
        case .bitcoinCash:
            return .bitcoinCash(testnet: false)
		case .litecoin:
			return .litecoin
        case .ethereum(let testnet):
            return .ethereum(testnet: testnet)
        case .dogecoin:
            return .dogecoin
        }
    }
}

enum BlockchairTarget: TargetType {
    case address(address: String, endpoint: BlockchairEndpoint, transactionDetails: Bool, apiKey: String)
    case fee(endpoint: BlockchairEndpoint, apiKey: String)
    case send(txHex: String, endpoint: BlockchairEndpoint, apiKey: String)

    case txDetails(txHash: String, endpoint: BlockchairEndpoint, apiKey: String)
    case txsDetails(hashes: [String], endpoint: BlockchairEndpoint, apiKey: String)
    case findErc20Tokens(address: String, endpoint: BlockchairEndpoint, apiKey: String)
    
    var baseURL: URL {
        var endpointString = ""
        
        switch self {
        case .address(_, let endpoint, _, _):
            endpointString = endpoint.path
        case .fee(let endpoint, _):
            endpointString = endpoint.path
        case .send(_, let endpoint, _):
            endpointString = endpoint.path
        case .txDetails(_, let endpoint, _):
            endpointString = endpoint.path
        case .txsDetails(_, let endpoint, _):
            endpointString = endpoint.path
        case .findErc20Tokens(_, let endpoint, _):
            endpointString = endpoint.path
        }
        
        return URL(string: "https://api.blockchair.com/\(endpointString)")!
    }
    
    var path: String {
        switch self {
        case .address(let address, _, _, _):
            return "/dashboards/address/\(address)"
        case .fee:
            return "/stats"
        case .send:
            return "/push/transaction"
        case .txDetails(let hash, _, _):
            return "/dashboards/transaction/\(hash)"
        case .txsDetails(let hashes, _, _):
            var path = "/dashboards/transactions/"
            if !hashes.isEmpty {
                hashes.forEach {
                    path.append($0)
                    path.append(",")
                }
                path.removeLast()
            }
            return path
        
        case .findErc20Tokens(let address, _, _):
            return "/dashboards/address/\(address)"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .address, .fee, .txDetails, .txsDetails, .findErc20Tokens:
            return .get
        case .send:
            return .post
        }
    }
    
    var sampleData: Data {
        return Data()
    }
    
    var task: Task {
        var parameters = [String:String]()
        var key: String
        switch self {
        case .address(_, _, let details, let apiKey):
            key = apiKey
            parameters["transaction_details"] = "\(details)"
        case .fee(_, let apiKey):
            key = apiKey
        case .send(let txHex, _, let apiKey):
            key = apiKey
            parameters["data"] = txHex
        case .txDetails(_, _, let apiKey), .txsDetails(_, _, let apiKey):
            key = apiKey
        case .findErc20Tokens(_, _, let apiKey):
            key = apiKey
            parameters["erc_20"] = "true"
        }
        parameters["key"] = key
        return .requestParameters(parameters: parameters, encoding: URLEncoding.default)
    }
    
    var headers: [String: String]? {
        switch self {
        case .address, .fee, .txDetails, .txsDetails, .findErc20Tokens:
            return ["Content-Type": "application/json"]
        case .send:
            return ["Content-Type": "application/x-www-form-urlencoded"]
        }
    }
}
