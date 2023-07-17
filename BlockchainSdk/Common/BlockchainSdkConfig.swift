//
//  BlockchainSdkConfig.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 14.12.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public struct BlockchainSdkConfig {
    let blockchairApiKeys: [String]
    let blockcypherTokens: [String]
    let infuraProjectId: String
    let nowNodesApiKey: String
    let getBlockApiKey: String
    let kaspaSecondaryApiUrl: String?
    let tronGridApiKey: String
    let tonCenterApiKeys: TonCenterApiKeys
    let fireacademyApiKeys: FireacamyApiKeys
    let quickNodeSolanaCredentials: QuickNodeCredentials
    let quickNodeBscCredentials: QuickNodeCredentials
    let blockscoutCredentials: NetworkProviderConfiguration.Credentials
    let defaultNetworkProviderConfiguration: NetworkProviderConfiguration
    let networkProviderConfigurations: [Blockchain: NetworkProviderConfiguration]

    public init(
        blockchairApiKeys: [String],
        blockcypherTokens: [String],
        infuraProjectId: String,
        nowNodesApiKey: String,
        getBlockApiKey: String,
        kaspaSecondaryApiUrl: String?,
        tronGridApiKey: String,
        tonCenterApiKeys: TonCenterApiKeys,
        fireacademyApiKeys: FireacamyApiKeys,
        quickNodeSolanaCredentials: QuickNodeCredentials,
        quickNodeBscCredentials: QuickNodeCredentials,
        blockscoutCredentials: NetworkProviderConfiguration.Credentials,
        defaultNetworkProviderConfiguration: NetworkProviderConfiguration = .init(),
        networkProviderConfigurations: [Blockchain: NetworkProviderConfiguration] = [:]
    ) {
        self.blockchairApiKeys = blockchairApiKeys
        self.blockcypherTokens = blockcypherTokens
        self.infuraProjectId = infuraProjectId
        self.nowNodesApiKey = nowNodesApiKey
        self.getBlockApiKey = getBlockApiKey
        self.kaspaSecondaryApiUrl = kaspaSecondaryApiUrl
        self.tronGridApiKey = tronGridApiKey
        self.tonCenterApiKeys = tonCenterApiKeys
        self.fireacademyApiKeys = fireacademyApiKeys
        self.quickNodeSolanaCredentials = quickNodeSolanaCredentials
        self.quickNodeBscCredentials = quickNodeBscCredentials
        self.blockscoutCredentials = blockscoutCredentials
        self.defaultNetworkProviderConfiguration = defaultNetworkProviderConfiguration
        self.networkProviderConfigurations = networkProviderConfigurations
    }

    func networkProviderConfiguration(for blockchain: Blockchain) -> NetworkProviderConfiguration {
        networkProviderConfigurations[blockchain] ?? defaultNetworkProviderConfiguration
    }
}

public extension BlockchainSdkConfig {
    struct QuickNodeCredentials {
        let apiKey: String
        let subdomain: String
        
        public init(apiKey: String, subdomain: String) {
            self.apiKey = apiKey
            self.subdomain = subdomain
        }
    }
    
    struct TonCenterApiKeys {
        let mainnetApiKey: String
        let testnetApiKey: String
        
        public init(mainnetApiKey: String, testnetApiKey: String) {
            self.mainnetApiKey = mainnetApiKey
            self.testnetApiKey = testnetApiKey
        }
        
        func getApiKey(for testnet: Bool) -> String {
            return testnet ? testnetApiKey : mainnetApiKey
        }
    }
    
    struct FireacamyApiKeys {
        let mainnetApiKey: String
        let testnetApiKey: String
        
        public init(mainnetApiKey: String, testnetApiKey: String) {
            self.mainnetApiKey = mainnetApiKey
            self.testnetApiKey = testnetApiKey
        }
        
        func getApiKey(for testnet: Bool) -> String {
            return testnet ? testnetApiKey : mainnetApiKey
        }
    }
}
