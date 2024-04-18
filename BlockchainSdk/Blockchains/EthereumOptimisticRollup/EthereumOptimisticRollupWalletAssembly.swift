//
//  EthereumOptimisticRollupWalletAssembly.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 16.04.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct EthereumOptimisticRollupWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        let providers = networkProviderAssembly.makeEthereumJsonRpcProviders(with: input)
        let txBuilder = try EthereumTransactionBuilder(chainId: input.blockchain.chainId)
        let networkService = EthereumNetworkService(
            decimals: input.blockchain.decimalCount,
            providers: providers,
            blockcypherProvider: nil,
            abiEncoder: WalletCoreABIEncoder()
        )

        return EthereumOptimisticRollupWalletManager(wallet: input.wallet, txBuilder: txBuilder, networkService: networkService)
    }
}
