//
//  NetworkProviderAssembly.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 09.02.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

protocol NetworkProviderAssemblyInput {
    var blockchain: Blockchain { get }
    var blockchainSdkConfig: BlockchainSdkConfig { get }
    var networkConfig: NetworkProviderConfiguration { get }
}

struct NetworkProviderAssembly {
    
    func makeBlockBookUtxoProvider(with input: NetworkProviderAssemblyInput, for type: BlockBookProviderType) -> BlockBookUtxoProvider {
        switch type {
        case .nowNodes:
            return BlockBookUtxoProvider(
                blockchain: input.blockchain,
                blockBookConfig: NowNodesBlockBookConfig(
                    apiKeyHeaderName: Constants.nowNodesApiKeyHeaderName,
                    apiKeyHeaderValue: input.blockchainSdkConfig.nowNodesApiKey
                ),
                networkConfiguration: input.networkConfig
            )
        case .getBlock:
            return BlockBookUtxoProvider(
                blockchain: input.blockchain,
                blockBookConfig: GetBlockBlockBookConfig(input.blockchainSdkConfig.getBlockCredentials),
                networkConfiguration: input.networkConfig
            )
        }
    }
    
    func makeBlockchainInfoNetworkProvider(with input: NetworkProviderAssemblyInput) -> BlockchainInfoNetworkProvider {
        return BlockchainInfoNetworkProvider(configuration: input.networkConfig)
    }
    
    func makeBlockcypherNetworkProvider(endpoint: BlockcypherEndpoint, with input: NetworkProviderAssemblyInput) -> BlockcypherNetworkProvider {
        return BlockcypherNetworkProvider(
            endpoint: endpoint,
            tokens: input.blockchainSdkConfig.blockcypherTokens,
            configuration: input.networkConfig
        )
    }
    
    func makeBlockchairNetworkProviders(endpoint: BlockchairEndpoint, with input: NetworkProviderAssemblyInput) -> [AnyBitcoinNetworkProvider] {
        let apiKeys: [String?] = [nil] + input.blockchainSdkConfig.blockchairApiKeys
        
        return apiKeys.map {
            BlockchairNetworkProvider(endpoint: endpoint, apiKey: $0, configuration: input.networkConfig)
                .eraseToAnyBitcoinNetworkProvider()
        }
    }
    
    func makeBlockscoutNetworkProvider(with input: NetworkProviderAssemblyInput) -> BlockscoutNetworkProvider {
        BlockscoutNetworkProvider(configuration: .init(credentials: input.blockchainSdkConfig.blockscoutCredentials))
    }
    
    func makeEthereumJsonRpcProviders(with input: NetworkProviderAssemblyInput) -> [EthereumJsonRpcProvider] {
        let endpoints = input.blockchain.getJsonRpcEndpoints(
            keys: EthereumApiKeys(
                infuraProjectId: input.blockchainSdkConfig.infuraProjectId,
                nowNodesApiKey: input.blockchainSdkConfig.nowNodesApiKey,
                getBlockApiKeys: input.blockchainSdkConfig.getBlockCredentials.credentials(type: .jsonRpc),
                quickNodeBscCredentials: input.blockchainSdkConfig.quickNodeBscCredentials
            )
        )!
        
        return endpoints.map {
            return EthereumJsonRpcProvider(
                url: $0,
                configuration: input.networkConfig
            )
        }
    }
    
}

extension NetworkProviderAssembly {
    struct Input: NetworkProviderAssemblyInput {
        let blockchainSdkConfig: BlockchainSdkConfig
        let blockchain: Blockchain

        var networkConfig: NetworkProviderConfiguration {
            blockchainSdkConfig.networkProviderConfiguration(for: blockchain)
        }
    }
}
