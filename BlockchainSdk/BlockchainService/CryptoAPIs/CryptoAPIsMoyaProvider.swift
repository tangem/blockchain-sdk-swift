//
//  CryptoAPIsMoyaProvider.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 10.06.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Moya
import Combine

class CryptoAPIsMoyaProvider: MoyaProvider<CryptoAPIsMoyaProvider.Target> {
    static let host = URL(string: "https://rest.cryptoapis.io/v2/")!
    
    let apiKey: String
    let coin: CoinType
    
    init(apiKey: String, coin: CoinType) {
        self.apiKey = apiKey
        self.coin = coin
    }
    
    func request(endpoint: Endpoint) -> AnyPublisher<Response, MoyaError> {
        let target = Target(apiKey: apiKey, coin: coin, endpoint: endpoint)
        return self.requestPublisher(target)
    }
}

// MARK: - Types

extension CryptoAPIsMoyaProvider {
    struct Target {
        let apiKey: String
        let coin: CoinType
        
        let endpoint: Endpoint
    }
    
    enum Endpoint {
        case address(address: String)
        case unconfirmedTransactions(address: String)
        case unspentOutputs(address: String)
    }
    
    enum CoinType {
        case dash
        
        var path: String {
            switch self {
            case .dash: return "dash"
            }
        }
        
        var network: String {
            /// CryptoAPIs uses only for testnet
            return "testnet"
        }
    }
}

// MARK: - TargetType

extension CryptoAPIsMoyaProvider.Target: TargetType {
    var baseURL: URL { CryptoAPIsMoyaProvider.host }
    
    var path: String {
        var path = "blockchain-data"
        path += "/" + coin.path
        path += "/" + coin.network
        
        switch endpoint {
        case let .address(address):
            path += "/addresses"
            path += "/" + address
            return path
            
        case let .unconfirmedTransactions(address):
            path += "/address-transactions-unconfirmed"
            path += "/" + address
            return path
            
        case let .unspentOutputs(address):
            path += "/addresses"
            path += "/" + address
            path += "/unspent-outputs"
            return path
        }
    }
    
    var method: Moya.Method {
        switch endpoint {
        case .address, .unconfirmedTransactions, .unspentOutputs:
            return .get
        }
    }
    
    var task: Task {
        switch endpoint {
        case .address, .unconfirmedTransactions, .unspentOutputs:
            return .requestPlain
        }
        
//        return .requestParameters(parameters: parameters, encoding: URLEncoding.default)
    }
    
    var headers: [String: String]? {
        switch endpoint {
        case .address, .unconfirmedTransactions, .unspentOutputs:
            return [
                "Content-Type": "application/json",
                "X-API-Key": apiKey
            ]
            
//        case .send:
//            return ["Content-Type": "application/x-www-form-urlencoded"]
        }
    }
}

