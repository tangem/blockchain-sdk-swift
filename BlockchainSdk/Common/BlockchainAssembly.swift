//
//  BlockchainAssemblyFactory.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 31.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk

struct BlockchainAssemblyInput {
    let blockchain: Blockchain
    let blockchainConfig: BlockchainSdkConfig
    let publicKey: Wallet.PublicKey
    let pairPublicKey: Data?
    let wallet: Wallet
    let networkConfig: NetworkProviderConfiguration
}

typealias AssemblyWallet = BaseManager & WalletManager

enum BlockBookProviderType {
    case NowNodes
    case GetBlock
}

protocol BlockchainAssemblyProtocol {
    
    /// Access to factory make factory blockchain
    /// - Parameter blockchain: Blockchain enum type
    /// - Returns: Is assembly result
    static func canAssembly(blockchain: Blockchain) -> Bool
    
    /// Blockchain assembly method
    /// - Parameter input: Input data factory
    /// - Returns: Blockchain result
    static func assembly(with input: BlockchainAssemblyInput) throws -> AssemblyWallet
    
    /// Helper BlockchairNetworkProviders
    static func makeBlockchairNetworkProviders(
        for endpoint: BlockchairEndpoint,
        configuration: NetworkProviderConfiguration,
        apiKeys: [String]
    ) -> [AnyBitcoinNetworkProvider]
    
    /// Make Provider for BlockBookUtx
    /// - Parameter input: Input data factory
    /// - Parameter type: Type of provider book
    /// - Returns: Provider model
    static func makeBlockBookUtxoProvider(with input: BlockchainAssemblyInput, for type: BlockBookProviderType) -> BlockBookUtxoProvider
    
    /// Make Provider for InfoNetwork
    /// - Parameter input: Input data factory
    /// - Parameter type: Type of provider book
    /// - Returns: Provider model
    static func makeInfoNetworkProvider(with input: BlockchainAssemblyInput) -> BlockchainInfoNetworkProvider
    
    /// Make provider for BlockcypherNetwork
    /// - Parameters:
    ///   - endpoint: Blockcypher endpoint
    ///   - input: Input data factory
    /// - Returns: Provider model
    static func makeBlockcypherNetworkProvider(endpoint: BlockcypherEndpoint, with input: BlockchainAssemblyInput) -> BlockcypherNetworkProvider
    
    /// Make provider for BlockchairNetwork
    /// - Parameters:
    ///   - endpoint: Blockchair endpoint
    ///   - input: Input data factory
    /// - Returns: Provider model
    static func makeBlockchairNetworkProviders(endpoint: BlockchairEndpoint, with input: BlockchainAssemblyInput) -> [AnyBitcoinNetworkProvider]
    
}

extension BlockchainAssemblyProtocol {
    
    static func makeBlockchairNetworkProviders(for endpoint: BlockchairEndpoint, configuration: NetworkProviderConfiguration, apiKeys: [String]) -> [AnyBitcoinNetworkProvider] {
        let apiKeys: [String?] = [nil] + apiKeys
        
        let providers = apiKeys.map {
            BlockchairNetworkProvider(endpoint: endpoint, apiKey: $0, configuration: configuration)
                .eraseToAnyBitcoinNetworkProvider()
        }
        
        return providers
    }
    
    static func makeBlockBookUtxoProvider(with input: BlockchainAssemblyInput, for type: BlockBookProviderType) -> BlockBookUtxoProvider {
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
    
    static func makeInfoNetworkProvider(with input: BlockchainAssemblyInput) -> BlockchainInfoNetworkProvider {
        return BlockchainInfoNetworkProvider(configuration: input.networkConfig)
    }
    
    static func makeBlockcypherNetworkProvider(endpoint: BlockcypherEndpoint, with input: BlockchainAssemblyInput) -> BlockcypherNetworkProvider {
        return BlockcypherNetworkProvider(
            endpoint: endpoint,
            tokens: input.blockchainConfig.blockcypherTokens,
            configuration: input.networkConfig
        )
    }
    
    static func makeBlockchairNetworkProviders(endpoint: BlockchairEndpoint, with input: BlockchainAssemblyInput) -> [AnyBitcoinNetworkProvider] {
        return makeBlockchairNetworkProviders(
            for: endpoint,
            configuration: input.networkConfig,
            apiKeys: input.blockchainConfig.blockchairApiKeys
        )
    }
    
}
