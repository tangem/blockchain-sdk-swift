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
        var providers: [NEARNetworkProvider] = []

        if blockchain.isTestnet {
            providers.append(
                NEARNetworkProvider(
                    baseURL: URL(string: "https://rpc.testnet.near.org")!,
                    configuration: input.networkConfig
                )
            )
        } else {
            let baseURLs = [
                "https://rpc.mainnet.near.org",
                "https://getblock.io/nodes/near/",  // TODO: Andrey Fedorov - Requires API key
                "https://near-mainnet.infura.io/v3/",   // TODO: Andrey Fedorov - Requires API key
                "https://near.nownodes.io/",    // TODO: Andrey Fedorov - Requires API key
            ]
            providers = baseURLs
                .map { URL(string: $0)! }
                .map { NEARNetworkProvider(baseURL: $0, configuration: input.networkConfig) }
        }

        let networkService = NEARNetworkService(blockchain: blockchain, providers: providers)
        let transactionBuilder = NEARTransactionBuilder(blockchain: blockchain)

        return NEARWalletManager(
            wallet: input.wallet,
            networkService: networkService,
            transactionBuilder: transactionBuilder
        )
    }
}
