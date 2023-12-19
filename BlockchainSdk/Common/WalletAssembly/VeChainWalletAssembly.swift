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
        let baseURLProvider = VeChainBaseURLProvider(blockchain: input.blockchain, sdkConfig: input.blockchainSdkConfig)
        let baseURLs = baseURLProvider.baseURLs()
        let networkProviders = baseURLs.map { VeChainNetworkProvider(baseURL: $0, configuration: input.networkConfig) }
        let networkService = VeChainNetworkService(providers: networkProviders)
        let transactionBuilder = VeChainTransactionBuilder()

        return VeChainWalletManager(
            wallet: input.wallet,
            networkService: networkService,
            transactionBuilder: transactionBuilder
        )
    }
}
