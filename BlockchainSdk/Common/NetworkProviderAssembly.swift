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
                blockBookConfig: NowNodesBlockBookConfig(apiKey: input.blockchainConfig.nowNodesApiKey),
                networkConfiguration: input.networkConfig
            )
        case .getBlock:
            return BlockBookUtxoProvider(
                blockchain: input.blockchain,
                blockBookConfig: GetBlockBlockBookConfig(apiKey: input.blockchainConfig.getBlockApiKey),
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
            tokens: input.blockchainConfig.blockcypherTokens,
            configuration: input.networkConfig
        )
    }
    
    func makeBlockchairNetworkProviders(endpoint: BlockchairEndpoint, with input: WalletManagerAssemblyInput) -> [AnyBitcoinNetworkProvider] {
        let apiKeys: [String?] = [nil] + input.blockchainConfig.blockchairApiKeys
        
        return apiKeys.map {
            BlockchairNetworkProvider(endpoint: endpoint, apiKey: $0, configuration: input.networkConfig)
                .eraseToAnyBitcoinNetworkProvider()
        }
    }
    
    func makeBlockscoutNetworkProvider(canLoad: Bool, with input: WalletManagerAssemblyInput) -> BlockscoutNetworkProvider? {
        return canLoad ? BlockscoutNetworkProvider(configuration: .init(credentials: input.blockchainConfig.blockscoutCredentials)) : nil
    }
    
    func makeEthereumJsonRpcProviders(with input: WalletManagerAssemblyInput) -> [EthereumJsonRpcProvider] {
        guard input.blockchain.isEvm else {
            assertionFailure("Don't use jsonRpc list for non-evm blockchains")
            return []
        }
        
        let provider = EthereumJsonRpcList(
            apiKeys: EthereumApiKeys(
                infuraProjectId: input.blockchainConfig.infuraProjectId,
                nowNodesApiKey: input.blockchainConfig.nowNodesApiKey,
                getBlockApiKey: input.blockchainConfig.getBlockApiKey,
                quickNodeBscCredentials: input.blockchainConfig.quickNodeBscCredentials
            )
        )
        
        return provider.getJsonRpc(for: input.blockchain)?.map {
            return EthereumJsonRpcProvider(
                url: $0,
                configuration: input.networkConfig
            )
        }
    }
    
}
