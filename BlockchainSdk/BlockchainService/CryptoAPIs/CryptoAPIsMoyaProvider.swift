//
//  CryptoAPIsMoyaProvider.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 10.06.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Moya
import Combine

class CryptoAPIsProvider: MoyaProvider<CryptoAPIsProvider.Target> {
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

extension CryptoAPIsProvider {
    struct Target {
        let apiKey: String
        let coin: CoinType
        
        let endpoint: Endpoint
    }
    
    enum Endpoint {
        case address(address: String)
        case unconfirmedTransactions(address: String)
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

