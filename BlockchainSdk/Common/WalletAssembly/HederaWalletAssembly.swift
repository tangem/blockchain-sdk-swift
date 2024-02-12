//
//  HederaWalletAssembly.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 25.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct HederaWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        let blockchain = input.blockchain
        let isTestnet = blockchain.isTestnet
        let networkConfig = input.networkConfig

        let targetConfigurationFactory = HederaTargetConfigurationFactory(
            isTestnet: isTestnet,
            sdkConfig: input.blockchainSdkConfig,
            helperNodeAPIVersion: .v1,
            mirrorNodeAPIVersion: .v1
        )

        let restProviders = targetConfigurationFactory
            .makeTargetConfigurations()
            .map { HederaRESTNetworkProvider(targetConfiguration: $0, providerConfiguration: networkConfig) }

        let consensusProvider = HederaConsensusNetworkProvider(isTestnet: isTestnet)

        let networkService = HederaNetworkService(
            blockchain: blockchain,
            consensusProvider: consensusProvider,
            restProviders: restProviders
        )

        let transactionBuilder = HederaTransactionBuilder()

        return HederaWalletManager(
            wallet: input.wallet,
            networkService: networkService,
            transactionBuilder: transactionBuilder
        )
    }
}
