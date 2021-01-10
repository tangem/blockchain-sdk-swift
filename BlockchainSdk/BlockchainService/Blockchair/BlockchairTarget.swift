//
//  BlockchairTarget.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 14.02.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Moya

enum BlockchairEndpoint: String {
	case bitcoin = "bitcoin"
    case bitcoinCash = "bitcoin-cash"
	case litecoin = "litecoin"
    
    var blockchain: Blockchain {
        switch self {
        case .bitcoin:
            return .bitcoin(testnet: false)
        case .bitcoinCash:
            return .bitcoinCash(testnet: false)
		case .litecoin:
			return .litecoin
        }
    }
}

enum BlockchairTarget: TargetType {
    case address(address: String, endpoint: BlockchairEndpoint = .bitcoinCash, transactionDetails: Bool, apiKey: String)
    case fee(endpoint: BlockchairEndpoint = .bitcoinCash, apiKey: String)
    case send(txHex: String, endpoint: BlockchairEndpoint = .bitcoinCash, apiKey: String)
    case txDetails(txHash: String, endpoint: BlockchairEndpoint = .bitcoin, apiKey: String)
    case txsDetails(hashes: [String], endpoint: BlockchairEndpoint = .bitcoin, apiKey: String)
    
    var baseURL: URL {
        var endpointString = ""
        
        switch self {
        case .address(_, let endpoint, _, _):
            endpointString = endpoint.rawValue
        case .fee(let endpoint, _):
            endpointString = endpoint.rawValue
        case .send(_, let endpoint, _):
            endpointString = endpoint.rawValue
        case .txDetails(_, let endpoint, _):
            endpointString = endpoint.rawValue
        case .txsDetails(_, let endpoint, _):
            endpointString = endpoint.rawValue
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
            if hashes.count > 0 {
                hashes.forEach {
                    path.append($0)
                    path.append(",")
                }
                path.removeLast()
            }
            return path
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .address, .fee, .txDetails, .txsDetails:
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
        }
        parameters["key"] = key
        return .requestParameters(parameters: parameters, encoding: URLEncoding.default)
    }
    
    var headers: [String: String]? {
        switch self {
        case .address, .fee, .txDetails, .txsDetails:
            return ["Content-Type": "application/json"]
        case .send:
            return ["Content-Type": "application/x-www-form-urlencoded"]
        }
    }
}
