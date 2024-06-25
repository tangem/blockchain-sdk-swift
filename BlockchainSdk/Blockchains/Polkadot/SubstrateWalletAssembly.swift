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
        let blockchain = input.blockchain

        guard let network = PolkadotNetwork(blockchain: blockchain) else {
            throw WalletError.empty
        }

        return PolkadotWalletManager(network: network, wallet: input.wallet).then { walletManager in
            let runtimeVersionProvider = SubstrateRuntimeVersionProvider(network: network)
            let providers = network.urls.map { url in
                PolkadotJsonRpcProvider(url: url, configuration: input.networkConfig)
            }

            walletManager.networkService = PolkadotNetworkService(providers: providers, network: network)
            walletManager.txBuilder = PolkadotTransactionBuilder(
                blockchain: blockchain,
                walletPublicKey: input.wallet.publicKey.blockchainKey,
                network: network,
                runtimeVersionProvider: runtimeVersionProvider
            )
        }
    }
}
