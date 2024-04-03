//
//  NEARWalletAssembly.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 12.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct NEARWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        let blockchain = input.blockchain
        let networkConfig = input.networkConfig

        let providers: [NEARNetworkProvider]
        let linkResolver = APILinkResolver(blockchain: blockchain, config: input.blockchainSdkConfig)
        if blockchain.isTestnet {
            providers = TestnetAPIURLProvider(blockchain: blockchain).urls()?.map {
                NEARNetworkProvider(baseURL: $0.url, configuration: networkConfig)
            } ?? []
        } else {
            providers = input.apiInfo.compactMap {
                guard
                    let link = linkResolver.resolve(for: $0),
                    let url = URL(string: link)
                else {
                    return nil
                }

                return NEARNetworkProvider(baseURL: url, configuration: networkConfig)
            }
        }

        let networkService = NEARNetworkService(blockchain: blockchain, providers: providers)
        let transactionBuilder = NEARTransactionBuilder()

        return NEARWalletManager(
            wallet: input.wallet,
            networkService: networkService,
            transactionBuilder: transactionBuilder,
            protocolConfigCache: .shared
        )
    }
}
