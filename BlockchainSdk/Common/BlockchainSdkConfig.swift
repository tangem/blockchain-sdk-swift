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
    let tronGridApiKey: String
    let quiknodeApiKey: String
    let quiknodeSubdomain: String
    let bscQuiknodeApiKey: String
    let bscQuiknodeSubdomain: String
    let defaultNetworkProviderConfiguration: NetworkProviderConfiguration
    let networkProviderConfigurations: [Blockchain: NetworkProviderConfiguration]

    public init(
        blockchairApiKeys: [String],
        blockcypherTokens: [String],
        infuraProjectId: String,
        tronGridApiKey: String,
        quiknodeApiKey: String,
        quiknodeSubdomain: String,
        bscQuiknodeApiKey: String,
        bscQuiknodeSubdomain: String,
        defaultNetworkProviderConfiguration: NetworkProviderConfiguration = .init(),
        networkProviderConfigurations: [Blockchain: NetworkProviderConfiguration] = [:]
    ) {
        self.blockchairApiKeys = blockchairApiKeys
        self.blockcypherTokens = blockcypherTokens
        self.infuraProjectId = infuraProjectId
        self.tronGridApiKey = tronGridApiKey
        self.quiknodeApiKey = quiknodeApiKey
        self.quiknodeSubdomain = quiknodeSubdomain
        self.bscQuiknodeApiKey = bscQuiknodeApiKey
        self.bscQuiknodeSubdomain = bscQuiknodeSubdomain
        self.defaultNetworkProviderConfiguration = defaultNetworkProviderConfiguration
        self.networkProviderConfigurations = networkProviderConfigurations
    }

    func networkProviderConfiguration(for blockchain: Blockchain) -> NetworkProviderConfiguration {
        networkProviderConfigurations[blockchain] ?? defaultNetworkProviderConfiguration
    }
}
