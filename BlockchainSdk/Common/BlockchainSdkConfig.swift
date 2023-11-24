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
    let getBlockAccessTokens: GetBlockBlockchainAccessTokens
    let kaspaSecondaryApiUrl: String?
    let tronGridApiKey: String
    let tonCenterApiKeys: TonCenterApiKeys
    let fireAcademyApiKeys: FireAcademyApiKeys
    let chiaTangemApiKeys: ChiaTangemApiKeys
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
        getBlockAccessTokens: GetBlockBlockchainAccessTokens,
        kaspaSecondaryApiUrl: String?,
        tronGridApiKey: String,
        tonCenterApiKeys: TonCenterApiKeys,
        fireAcademyApiKeys: FireAcademyApiKeys,
        chiaTangemApiKeys: ChiaTangemApiKeys,
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
        self.getBlockAccessTokens = getBlockAccessTokens
        self.kaspaSecondaryApiUrl = kaspaSecondaryApiUrl
        self.tronGridApiKey = tronGridApiKey
        self.tonCenterApiKeys = tonCenterApiKeys
        self.fireAcademyApiKeys = fireAcademyApiKeys
        self.chiaTangemApiKeys = chiaTangemApiKeys
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
    
    struct FireAcademyApiKeys {
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
    
    struct ChiaTangemApiKeys {
        let mainnetApiKey: String
        
        public init(mainnetApiKey: String) {
            self.mainnetApiKey = mainnetApiKey
        }
    }
    
    struct GetBlockBlockchainAccessTokens {
        let credentials: [Credential]
        
        public init(credentials: [Credential]) {
            self.credentials = credentials
        }
        
        func credential(
            for blockchain: Blockchain,
            at type: BlockchainSdkConfig.GetBlockBlockchainAccessTokens.Credential.TypeValue
        ) -> String {
            return credentials.first {
                $0.blockchain == blockchain && $0.type == type
            }?.key ?? ""
        }
        
        public struct Credential {
            let blockchain: Blockchain
            let type: TypeValue
            let key: String
            
            public init(blockchain: Blockchain, type: TypeValue, key: String) {
                self.blockchain = blockchain
                self.type = type
                self.key = key
            }
            
            public enum TypeValue {
                case blockBook
                case rest
                case jsonRpc
                case rosseta
            }
        }
    }
}
