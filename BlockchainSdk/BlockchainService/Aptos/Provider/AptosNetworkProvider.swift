//
//  AptosNetworkProvider.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 26.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import SwiftyJSON

struct AptosNetworkProvider: HostProvider {
    // MARK: - HostProvider
    
    /// Blockchain API host
    var host: String {
        node.host
    }
    
    /// Configuration connection node for provider
    private let node: AptosProviderNode
    
    // MARK: - Properties
    
    /// Network provider of blockchain
    private let network: NetworkProvider<AptosProviderTarget>
    
    // MARK: - Init
    
    init(
        node: AptosProviderNode,
        networkConfig: NetworkProviderConfiguration
    ) {
        self.node = node
        self.network = .init(configuration: networkConfig)
    }
    
    // MARK: - Implementation
    
    func getAccountResources(address: String) -> AnyPublisher<JSON, Error> {
        let target = AptosProviderTarget(
            node: node,
            targetType: .accountsResources(address: address)
        )
        
        return requestPublisher(for: target)
    }
    
    // MARK: - Private Implementation
    
    private func requestPublisher(for target: AptosProviderTarget) -> AnyPublisher<JSON, Error> {
        return network.requestPublisher(target)
            .filterSuccessfulStatusAndRedirectCodes()
            .mapSwiftyJSON()
            .mapError { moyaError -> Swift.Error in
                return moyaError.asWalletError ?? moyaError
            }
            .eraseToAnyPublisher()
    }
    
}
