//
//  ProviderAssembly.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 09.02.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct ProviderAssembly {
    
    func makeBlockBookUtxoProvider(with input: BlockchainAssemblyInput, for type: BlockBookProviderType) -> BlockBookUtxoProvider {
        switch type {
        case .NowNodes:
            return BlockBookUtxoProvider(
                blockchain: input.blockchain,
                blockBookConfig: GetBlockBlockBookConfig(apiKey: input.blockchainConfig.getBlockApiKey),
                networkConfiguration: input.networkConfig
            )
        case .GetBlock:
            return BlockBookUtxoProvider(
                blockchain: input.blockchain,
                blockBookConfig: GetBlockBlockBookConfig(apiKey: input.blockchainConfig.getBlockApiKey),
                networkConfiguration: input.networkConfig
            )
        }
    }
    
    func makeInfoNetworkProvider(with input: BlockchainAssemblyInput) -> BlockchainInfoNetworkProvider {
        return BlockchainInfoNetworkProvider(configuration: input.networkConfig)
    }
    
    func makeBlockcypherNetworkProvider(endpoint: BlockcypherEndpoint, with input: BlockchainAssemblyInput) -> BlockcypherNetworkProvider {
        return BlockcypherNetworkProvider(
            endpoint: endpoint,
            tokens: input.blockchainConfig.blockcypherTokens,
            configuration: input.networkConfig
        )
    }
    
    func makeBlockchairNetworkProviders(endpoint: BlockchairEndpoint, with input: BlockchainAssemblyInput) -> [AnyBitcoinNetworkProvider] {
        return makeBlockchairNetworkProviders(
            for: endpoint,
            configuration: input.networkConfig,
            apiKeys: input.blockchainConfig.blockchairApiKeys
        )
    }
    
    // MARK: - Private Implementation
    
    private func makeBlockchairNetworkProviders(for endpoint: BlockchairEndpoint, configuration: NetworkProviderConfiguration, apiKeys: [String]) -> [AnyBitcoinNetworkProvider] {
        let apiKeys: [String?] = [nil] + apiKeys
        
        let providers = apiKeys.map {
            BlockchairNetworkProvider(endpoint: endpoint, apiKey: $0, configuration: configuration)
                .eraseToAnyBitcoinNetworkProvider()
        }
        
        return providers
    }
    
}
