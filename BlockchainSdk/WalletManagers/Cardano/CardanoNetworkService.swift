//
//  CardanoNetworkService.swift
//  BlockchainSdk
//
//  Created by Andrew Son on 10/03/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol CardanoNetworkProvider: HostProvider {
    func getInfo(addresses: [String]) -> AnyPublisher<CardanoAddressResponse, Error>
    func send(transaction: Data) -> AnyPublisher<String, Error>
}

extension CardanoNetworkProvider {
    func eraseToAnyCardanoNetworkProvider() -> AnyCardanoNetworkProvider {
        AnyCardanoNetworkProvider(self)
    }
}

class AnyCardanoNetworkProvider: CardanoNetworkProvider {
    var host: String { provider.host }
    
    private let provider: CardanoNetworkProvider
    
    init<P: CardanoNetworkProvider>(_ provider: P) {
        self.provider = provider
    }
    
    func getInfo(addresses: [String]) -> AnyPublisher<CardanoAddressResponse, Error> {
        provider.getInfo(addresses: addresses)
    }
    
    func send(transaction: Data) -> AnyPublisher<String, Error> {
        provider.send(transaction: transaction)
    }
}

class CardanoNetworkService: MultiNetworkProvider, CardanoNetworkProvider {
    let blockchain: Blockchain
    let providers: [AnyCardanoNetworkProvider]
    
    var currentProviderIndex: Int = 0
    
    init(blockchain: Blockchain, providers: [AnyCardanoNetworkProvider]) {
        self.blockchain = blockchain
        self.providers = providers
    }
    
    func getInfo(addresses: [String]) -> AnyPublisher<CardanoAddressResponse, Error> {
        providerPublisher { $0.getInfo(addresses: addresses) }
    }
    
    func send(transaction: Data) -> AnyPublisher<String, Error> {
        providerPublisher { $0.send(transaction: transaction) }
    }
}

public struct CardanoAddressResponse {
    let balance: Decimal
    let recentTransactionsHashes: [String]
    let unspentOutputs: [CardanoUnspentOutput]
}

public struct CardanoUnspentOutput {
    let address: String
    let amount: Decimal
    let outputIndex: Int
    let transactionHash: String
}
