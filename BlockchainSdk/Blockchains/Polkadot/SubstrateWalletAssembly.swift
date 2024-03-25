//
//  KusumaWalletAssembly.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 08.02.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct SubstrateWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        guard let network = PolkadotNetwork(blockchain: input.blockchain) else {
            throw WalletError.empty
        }
        
        return PolkadotWalletManager(
            network: network,
            wallet: input.wallet,
            accountHealthChecker: makeAccountHealthChecker(for: network, input: input)
        )
        .then {
            let providers = network.urls.map { url in
                PolkadotJsonRpcProvider(url: url, configuration: input.networkConfig)
            }
            $0.networkService = PolkadotNetworkService(providers: providers, network: network)
            $0.txBuilder = PolkadotTransactionBuilder(
                blockchain: input.blockchain,
                walletPublicKey: input.wallet.publicKey.blockchainKey,
                network: network
            )
        }
    }

    private func makeAccountHealthChecker(
        for network: PolkadotNetwork,
        input: WalletManagerAssemblyInput
    ) -> PolkaDotAccountHealthChecker? {
        switch network {
        case .polkadot:
            let networkService = SubscanPolkadotAccountHealthNetworkService(isTestnet: false)
            let analytics = input.blockchainSdkDependencies.blockchainAnalytics
            return PolkaDotAccountHealthChecker(networkService: networkService, analytics: analytics)
        case .westend:
            let networkService = SubscanPolkadotAccountHealthNetworkService(isTestnet: true)
            let analytics = input.blockchainSdkDependencies.blockchainAnalytics
            return PolkaDotAccountHealthChecker(networkService: networkService, analytics: analytics)
        case .kusama, .azero:
            return nil
        }
    }
}
