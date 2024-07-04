//
//  KoinosNetworkService.swift
//  BlockchainSdk
//
//  Created by Aleksei Muraveinik on 27.05.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import BigInt
import Combine

class KoinosNetworkService: MultiNetworkProvider {
    let providers: [KoinosNetworkProvider]
    var currentProviderIndex = 0
    
    init(providers: [KoinosNetworkProvider]) {
        self.providers = providers
    }
    
    func getInfo(address: String) -> AnyPublisher<KoinosAccountInfo, Error> {
        providerPublisher { provider in
            provider.getInfo(address: address)
        }
    }
    
    func getCurrentNonce(address: String) -> AnyPublisher<KoinosAccountNonce, Error> {
        providerPublisher { provider in
            provider.getNonce(address: address)
        }
    }
    
    func getRCLimit() -> AnyPublisher<BigUInt, Error> {
        providerPublisher { provider in
            provider.getRCLimit()
        }
    }
    
    func submitTransaction(transaction: KoinosProtocol.Transaction) -> AnyPublisher<KoinosTransactionEntry, Error> {
        providerPublisher { provider in
            provider.submitTransaction(transaction: transaction)
        }
    }
    
    func isTransactionExist(transactionID: String) -> AnyPublisher<Bool, Error> {
        providerPublisher { provider in
            provider.isTransactionExist(transactionID: transactionID)
        }
    }
}
