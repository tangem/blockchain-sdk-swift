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
    
    private var blockchain: Blockchain
    
    // MARK: - Init
    
    init(providers: [AlgorandNetworkProvider], blockchain: Blockchain) {
        self.providers = providers
        self.blockchain = blockchain
    }
    
    // MARK: - Implementation
    
    func getAccount(address: String) -> AnyPublisher<AlgorandResponse.Account, Error> {
        providerPublisher { provider in
            provider
                .getAccount(address: address)
                .map { response in
                    return response
                }
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
}
