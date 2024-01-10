//
//  VeChainWalletAssembly.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 18.12.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct VeChainWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        let blockchain = input.blockchain
        let sdkConfig = input.blockchainSdkConfig
        let networkConfig = input.networkConfig
        let baseURLProvider = VeChainBaseURLProvider(blockchain: blockchain, sdkConfig: sdkConfig)
        let baseURLs = baseURLProvider.baseURLs()
        let networkProviders = baseURLs.map { VeChainNetworkProvider(baseURL: $0, configuration: networkConfig) }

        let networkService = VeChainNetworkService(
            blockchain: blockchain,
            providers: networkProviders
        )

        let transactionBuilder = VeChainTransactionBuilder()

        return VeChainWalletManager(
            wallet: input.wallet,
            networkService: networkService,
            transactionBuilder: transactionBuilder
        )
    }
}
