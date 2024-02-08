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
        let networkConfig = input.networkConfig

        let baseURLProvider = HederaBaseURLProvider(isTestnet: blockchain.isTestnet)
        let mirrorProviders = baseURLProvider
            .baseURLs()
            .map { HederaMirrorNetworkProvider(baseURL: $0, configuration: networkConfig) }

        let consensusProvider = HederaConsensusNetworkProvider(configuration: networkConfig)

        let networkService = HederaNetworkService(
            blockchain: blockchain,
            consensusProvider: consensusProvider,
            mirrorProviders: mirrorProviders
        )

        let transactionBuilder = HederaTransactionBuilder()

        return HederaWalletManager(
            wallet: input.wallet,
            networkService: networkService,
            transactionBuilder: transactionBuilder
        )
    }
}
