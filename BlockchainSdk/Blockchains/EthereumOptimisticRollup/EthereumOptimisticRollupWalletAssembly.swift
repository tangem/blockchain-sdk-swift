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

        return try EthereumOptimisticRollupWalletManager(wallet: input.wallet).then { walletManager in
            guard let chainId = input.blockchain.chainId else {
                throw WalletError.empty
            }

            walletManager.txBuilder = try EthereumTransactionBuilder(
                walletPublicKey: input.wallet.publicKey.blockchainKey,
                chainId: chainId
            )
            walletManager.networkService = EthereumNetworkService(
                decimals: input.blockchain.decimalCount,
                providers: providers,
                blockcypherProvider: nil,
                abiEncoder: WalletCoreABIEncoder()
            )
        }
    }
}
