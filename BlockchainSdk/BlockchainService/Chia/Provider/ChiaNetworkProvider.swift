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
    
}
