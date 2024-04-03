//
//  AlgorandWalletAssembly.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 09.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct AlgorandWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        var providers: [AlgorandNetworkProvider] = []

        let blockchain = input.blockchain
        let networkConfig = input.networkConfig

        if blockchain.isTestnet {
            providers = TestnetAPIURLProvider(blockchain: blockchain).urls()?.compactMap {
                AlgorandNetworkProvider(
                    node: .init(url: $0.url, apiKeyInfo: nil),
                    networkConfig: networkConfig
                )
            } ?? []
        } else {
            let config = input.blockchainSdkConfig
            let linkResolver = APILinkResolver(blockchain: blockchain, config: config)
            let apiKeyInfoProvider = APIKeysInfoProvider(blockchain: blockchain, config: config)

            providers = input.apiInfo.compactMap {
                guard
                    let link = linkResolver.resolve(for: $0),
                    let url = URL(string: link)
                else {
                    return nil
                }

                let apiKeyInfo = apiKeyInfoProvider.apiKeys(for: $0.api)
                return AlgorandNetworkProvider(
                    node: .init(url: url, apiKeyInfo: apiKeyInfo),
                    networkConfig: networkConfig)
            }
        }

        let transactionBuilder = AlgorandTransactionBuilder(
            publicKey: input.wallet.publicKey.blockchainKey, 
            curve: input.wallet.blockchain.curve,
            isTestnet: input.blockchain.isTestnet
        )
        
        return try AlgorandWalletManager(
            wallet: input.wallet, 
            transactionBuilder: transactionBuilder, 
            networkService: .init(blockchain: input.wallet.blockchain, providers: providers)
        )
    }
}
