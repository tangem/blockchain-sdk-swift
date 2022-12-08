//
//  BlockchainSdkConfig.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 14.12.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public struct BlockchainSdkConfig {
    let blockchairApiKey: String
    let blockcypherTokens: [String]
    let infuraProjectId: String
    let tronGridApiKey: String
    let quiknodeApiKey: String
    let quiknodeSubdomain: String
    let defaultNetworkProviderConfiguration: NetworkProviderConfiguration
    let networkProviderConfigurations: [Blockchain: NetworkProviderConfiguration]

    public init(
        blockchairApiKey: String,
        blockcypherTokens: [String],
        infuraProjectId: String,
        tronGridApiKey: String,
        quiknodeApiKey: String,
        quiknodeSubdomain: String,
        defaultNetworkProviderConfiguration: NetworkProviderConfiguration = .init(),
        networkProviderConfigurations: [Blockchain: NetworkProviderConfiguration] = [:]
    ) {
        self.blockchairApiKey = blockchairApiKey
        self.blockcypherTokens = blockcypherTokens
        self.infuraProjectId = infuraProjectId
        self.tronGridApiKey = tronGridApiKey
        self.quiknodeApiKey = quiknodeApiKey
        self.quiknodeSubdomain = quiknodeSubdomain
        self.defaultNetworkProviderConfiguration = defaultNetworkProviderConfiguration
        self.networkProviderConfigurations = networkProviderConfigurations
    }

    func networkProviderConfiguration(for blockchain: Blockchain) -> NetworkProviderConfiguration {
        networkProviderConfigurations[blockchain] ?? defaultNetworkProviderConfiguration
    }
}
