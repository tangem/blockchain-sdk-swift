//
//  ChiaNetworkProvider.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 14.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

struct ChiaNetworkProvider: HostProvider {
    
    // MARK: - HostProvider
    
    /// Blockchain API host
    var host: String {
        node.endpoint.url.hostOrUnknown
    }
    
    /// Configuration connection node for provider
    private let node: ChiaNetworkNode
    
    // MARK: - Properties
    
    /// Network provider of blockchain
    private let network: NetworkProvider<ChiaProviderTarget>
    
    // MARK: - Init
    
    init(
        node: ChiaNetworkNode,
        networkConfig: NetworkProviderConfiguration
    ) {
        self.node = node
        self.network = .init(configuration: networkConfig)
    }
    
    // MARK: - Implementation
    
    func getUnspents(puzzleHash: String) -> AnyPublisher<ChiaCoinRecordsResponse, Error> {
        let target = ChiaProviderTarget(
            node: node,
            targetType: .getCoinRecordsBy(puzzleHashBody: .init(puzzleHash: puzzleHash))
        )
        
        return requestPublisher(for: target)
    }
    
    func sendTransaction(body: ChiaTransactionBody) -> AnyPublisher<Void, Error> {
        return .emptyFail
    }
    
    // MARK: - Private Implementation
    
    private func requestPublisher<T: Decodable>(for target: ChiaProviderTarget) -> AnyPublisher<T, Error> {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        return network.requestPublisher(target)
            .filterSuccessfulStatusAndRedirectCodes()
            .map(T.self, using: decoder)
            .mapError { error in
                print(error.localizedDescription)
                return WalletError.empty
            }
            .eraseToAnyPublisher()
    }
    
}
