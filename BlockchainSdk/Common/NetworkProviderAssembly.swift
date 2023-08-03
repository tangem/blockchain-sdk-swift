//
//  NetworkProviderAssembly.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 09.02.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct NetworkProviderAssembly {
    
    func makeBlockBookUtxoProvider(with input: WalletManagerAssemblyInput, for type: BlockBookProviderType) -> BlockBookUtxoProvider {
        switch type {
        case .nowNodes:
            return BlockBookUtxoProvider(
                blockchain: input.blockchain,
                blockBookConfig: NowNodesBlockBookConfig(apiKey: input.blockchainSdkConfig.nowNodesApiKey),
                networkConfiguration: input.networkConfig
            )
        case .getBlock:
            return BlockBookUtxoProvider(
                blockchain: input.blockchain,
                blockBookConfig: GetBlockBlockBookConfig(apiKey: input.blockchainSdkConfig.getBlockApiKey),
                networkConfiguration: input.networkConfig
            )
        }
    }
    
    func makeBlockchainInfoNetworkProvider(with input: WalletManagerAssemblyInput) -> BlockchainInfoNetworkProvider {
        return BlockchainInfoNetworkProvider(configuration: input.networkConfig)
    }
    
    func makeBlockcypherNetworkProvider(endpoint: BlockcypherEndpoint, with input: WalletManagerAssemblyInput) -> BlockcypherNetworkProvider {
        return BlockcypherNetworkProvider(
            endpoint: endpoint,
            tokens: input.blockchainSdkConfig.blockcypherTokens,
            configuration: input.networkConfig
        )
    }
    
    func makeBlockchairNetworkProviders(endpoint: BlockchairEndpoint, with input: WalletManagerAssemblyInput) -> [AnyBitcoinNetworkProvider] {
        let apiKeys: [String?] = [nil] + input.blockchainSdkConfig.blockchairApiKeys
        
        return apiKeys.map {
            BlockchairNetworkProvider(endpoint: endpoint, apiKey: $0, configuration: input.networkConfig)
                .eraseToAnyBitcoinNetworkProvider()
        }
    }
    
    func makeBlockscoutNetworkProvider(with input: WalletManagerAssemblyInput) -> BlockscoutNetworkProvider {
        BlockscoutNetworkProvider(configuration: .init(credentials: input.blockchainSdkConfig.blockscoutCredentials))
    }
    
    func makeEthereumJsonRpcProviders(with input: WalletManagerAssemblyInput) -> [EthereumJsonRpcProvider] {
        let endpoints = input.blockchain.getJsonRpcEndpoints(
            keys: EthereumApiKeys(
                infuraProjectId: input.blockchainSdkConfig.infuraProjectId,
                nowNodesApiKey: input.blockchainSdkConfig.nowNodesApiKey,
                getBlockApiKey: input.blockchainSdkConfig.getBlockApiKey,
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
