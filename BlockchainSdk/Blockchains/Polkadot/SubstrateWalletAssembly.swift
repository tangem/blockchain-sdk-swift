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
        
        return PolkadotWalletManager(network: network, wallet: input.wallet).then {
            let blockchain = input.blockchain
            let networkConfig = input.networkConfig
            let providers: [PolkadotJsonRpcProvider]
            if blockchain.isTestnet {
                providers = TestnetAPIURLProvider(blockchain: blockchain).urls()?.map {
                    PolkadotJsonRpcProvider(url: $0.url, configuration: networkConfig)
                } ?? []
            } else {
                let linkResolver = APILinkResolver(blockchain: input.blockchain, config: input.blockchainSdkConfig)
                 providers = input.apiInfo.compactMap {
                    guard
                        let link = linkResolver.resolve(for: $0),
                        let url = URL(string: link)
                    else {
                        return nil
                    }

                    return PolkadotJsonRpcProvider(url: url, configuration: input.networkConfig)
                }
            }
            $0.networkService = PolkadotNetworkService(providers: providers, network: network)
            $0.txBuilder = PolkadotTransactionBuilder(blockchain: input.blockchain, walletPublicKey: input.wallet.publicKey.blockchainKey, network: network)
        }
    }
}
