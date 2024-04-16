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
        return try EthereumOptimisticRollupWalletManager(wallet: input.wallet).then {
            let chainId = input.blockchain.chainId!

            $0.txBuilder = try EthereumTransactionBuilder(walletPublicKey: input.wallet.publicKey.blockchainKey, chainId: chainId)
            $0.networkService = EthereumNetworkService(
                decimals: input.blockchain.decimalCount,
                providers: providers,
                blockcypherProvider: nil,
                abiEncoder: WalletCoreABIEncoder()
            )
        }
    }

}
