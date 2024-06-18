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

        guard
            let network = PolkadotNetwork(blockchain: blockchain),
            let runtimeVersion = runtimeVersion(for: blockchain)
        else {
            throw WalletError.empty
        }

        return PolkadotWalletManager(network: network, wallet: input.wallet).then { walletManager in
            let networkConfig = input.networkConfig
            let providers = network.urls.map { url in
                PolkadotJsonRpcProvider(url: url, configuration: input.networkConfig)
            }

            walletManager.networkService = PolkadotNetworkService(providers: providers, network: network)
            walletManager.txBuilder = PolkadotTransactionBuilder(
                blockchain: blockchain,
                walletPublicKey: input.wallet.publicKey.blockchainKey,
                network: network,
                runtimeVersion: runtimeVersion
            )
        }
    }

    private func runtimeVersion(for blockchain: Blockchain) -> SubstrateRuntimeVersion? {
        switch blockchain {
        case .polkadot(_, true),
             .kusama:
            return .v15
        case .polkadot(_, false),
             .azero:
            // TODO: Andrey Fedorov - Migrate to v15 runtime (IOS-7157)
            return .v14
        default:
            return nil
        }
    }
    
}
