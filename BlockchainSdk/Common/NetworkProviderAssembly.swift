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
    var apiOrder: APIOrder { get }
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
    
    func makeBitcoinCashNowNodesNetworkProvider(
        input: NetworkProviderAssemblyInput,
        bitcoinCashAddressService: BitcoinCashAddressService
    ) -> AnyBitcoinNetworkProvider {
        return BitcoinCashNowNodesNetworkProvider(
            blockBookUtxoProvider: makeBlockBookUtxoProvider(with: input, for: .nowNodes),
            bitcoinCashAddressService: bitcoinCashAddressService
        ).eraseToAnyBitcoinNetworkProvider()
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
    
    func makeEthereumJsonRpcProviders(with input: NetworkProviderAssemblyInput) -> [EthereumJsonRpcProvider] {
        let endpoints = input.blockchain.getJsonRpcEndpoints(
            keys: EthereumApiKeys(
                infuraProjectId: input.blockchainSdkConfig.infuraProjectId,
                nowNodesApiKey: input.blockchainSdkConfig.nowNodesApiKey,
                getBlockApiKeys: input.blockchainSdkConfig.getBlockCredentials.credentials(type: .jsonRpc),
                quickNodeBscCredentials: input.blockchainSdkConfig.quickNodeBscCredentials
            )
        )!

//        let urls: [URL] = input.apiInfo.compactMap { info in
//            if let provider = info.provider, let api = API(rawValue: provider) {
//                guard info.type == .private else {
//                    return nil
//                }
//
//                guard let link = info.url else {
//                    return nil
//                }
//
//                switch api {
//                case .nownodes:
//                    if case .avalanche = input.blockchain {
//                        var components = URLComponents(string: link)
//
//                    }
//
//                    return URL(string: link)?
//                        .appendingPathComponent(input.blockchainSdkConfig.nowNodesApiKey)
//                case .getBlock:
//                    if case .avalanche = input.blockchain {
//                        return nil
//                    }
//
//                    return URL(string: link)?
//                        .appendingPathComponent(input.blockchainSdkConfig.getBlockCredentials[input.blockchain] ?? "")
//                case .quicknode:
//                    var components = URLComponents(string: link)
//                    components.
//                case .ton:
//                    <#code#>
//                case .tron:
//                    <#code#>
//                case .hedera:
//                    <#code#>
//                case .infura:
//                    <#code#>
//                }
//            }
//        }

        return endpoints.map {
            return EthereumJsonRpcProvider(
                url: $0,
                configuration: input.networkConfig
            )
        }
    }
    
//    private func makeGetBlockJsonRpcProvider() -> URL {
//        if let jsonRpcKey = getBlockApiKeys[self] {
//            return URL(string: "https://go.getblock.io/\(jsonRpcKey)")!
//        } else {
//            assertionFailure("getJsonRpcEndpoints -> Not found GetBlock jsonRpc key for blockchain \(displayName)")
//            Log.network("Not found jsonRpc key GetBlock API for blockchaib \(displayName)")
//            return URL(string: "https://go.getblock.io/")!
//        }
//    }
}

extension NetworkProviderAssembly {
    struct Input: NetworkProviderAssemblyInput {
        let blockchainSdkConfig: BlockchainSdkConfig
        let blockchain: Blockchain
        let apiOrder: APIOrder

        var networkConfig: NetworkProviderConfiguration {
            blockchainSdkConfig.networkProviderConfiguration(for: blockchain)
        }
    }
}
