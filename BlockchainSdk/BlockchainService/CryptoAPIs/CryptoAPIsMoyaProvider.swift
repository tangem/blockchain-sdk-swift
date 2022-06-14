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
        return requestPublisher(target)
                .filterSuccessfulStatusCodes()
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
        case confirmedTransactions(address: String)
        case unspentOutputs(address: String)
        case fee
        case push(hex: String)
    }
    
    enum CoinType {
        case dash
        
        var path: String {
            switch self {
            case .dash: return "dash"
            }
        }
        
        var network: String {
            /// CryptoAPIs only used for testnet because we have the free version
            return "testnet"
        }
    }
}

// MARK: - TargetType

extension CryptoAPIsMoyaProvider.Target: TargetType {
    var baseURL: URL { CryptoAPIsMoyaProvider.host }
    
    var path: String {
        var path = ""
        
        if case .push = endpoint {
            path += "blockchain-tools"
        } else {
            path += "blockchain-data"
        }
        
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
        case let .confirmedTransactions(address):
            path += "/addresses"
            path += "/" + address
            path += "/transactions"
            return path
        case let .unspentOutputs(address):
            path += "/addresses"
            path += "/" + address
            path += "/unspent-outputs"
            return path
        case .fee:
            path += "/mempool/fees"
            return path
        case .push:
            path += "/transactions/broadcast"
            return path
        }
    }
    
    var method: Moya.Method {
        switch endpoint {
        case .address, .unconfirmedTransactions, .unspentOutputs, .fee, .confirmedTransactions:
            return .get
        case .push:
            return .post
        }
    }
    
    var task: Task {
        switch endpoint {
        case .address, .unconfirmedTransactions, .unspentOutputs, .fee, .confirmedTransactions:
            return .requestPlain
        case let .push(hex):
            let requestModel = CryptoAPIsPushTxRequest(signedTransactionHex: hex)
            let encodable = CryptoAPIsBase<CryptoAPIsBaseItem<CryptoAPIsPushTxRequest>>(
                data: .init(item: requestModel)
            )
            return .requestJSONEncodable(encodable)
        }
    }
    
    var headers: [String: String]? {
        switch endpoint {
        case .address, .unconfirmedTransactions, .unspentOutputs, .fee, .confirmedTransactions, .push:
            return [
                "Content-Type": "application/json",
                "X-API-Key": apiKey,
            ]
        }
    }
}

