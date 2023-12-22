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

        let energyToken = Token(
            name: Constants.energyTokenName,
            symbol: Constants.energyTokenSymbol,
            contractAddress: Constants.energyTokenContractAddress,
            decimalCount: blockchain.decimalCount
        )

        let networkService = VeChainNetworkService(
            blockchain: blockchain,
            energyToken: energyToken,
            providers: networkProviders
        )

        let transactionBuilder = VeChainTransactionBuilder(blockchain: blockchain)

        return VeChainWalletManager(
            wallet: input.wallet,
            energyToken: energyToken,
            networkService: networkService,
            transactionBuilder: transactionBuilder
        )
    }
}

// MARK: - Constants

private extension VeChainWalletAssembly {
    enum Constants {
        /// See https://docs.vechain.org/introduction-to-vechain/dual-token-economic-model/vethor-vtho for details and specs.
        static let energyTokenName = "VeThor"
        static let energyTokenSymbol = "VTHO"
        static let energyTokenContractAddress = "0x0000000000000000000000000000456e65726779"
    }
}
