//
//  AlgorandNetworkService.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 10.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class AlgorandNetworkService: MultiNetworkProvider {
    // MARK: - Protperties
    
    let providers: [AlgorandNetworkProvider]
    var currentProviderIndex: Int = 0
    
    // MARK: - Init
    
    init(providers: [AlgorandNetworkProvider]) {
        self.providers = providers
    }
    
    // MARK: - Implementation
    
    func getAccount(address: String) -> AnyPublisher<AlgorandResponse.Account, Error> {
        providerPublisher { provider in
            provider
                .getAccount(address: address)
                .eraseToAnyPublisher()
        }
    }
    
    func getTransactionParams() -> AnyPublisher<AlgorandResponse.TransactionParams, Error> {
        providerPublisher { provider in
            provider
                .getTransactionParams()
                .eraseToAnyPublisher()
        }
    }
    
    func sendTransaction(hash: String) -> AnyPublisher<String, Error> {
        providerPublisher { provider in
            provider
                .sendTransaction(hash: hash)
                .eraseToAnyPublisher()
        }
    }
}
