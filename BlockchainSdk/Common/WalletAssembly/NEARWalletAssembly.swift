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
        let sdkConfig = input.blockchainSdkConfig
        let networkConfig = input.networkConfig
        let baseURLs = baseURLs(for: blockchain, with: sdkConfig)
        let networkProviders = baseURLs.map { NEARNetworkProvider(baseURL: $0, configuration: networkConfig) }
        let networkService = NEARNetworkService(blockchain: blockchain, providers: networkProviders)
        let transactionBuilder = NEARTransactionBuilder(blockchain: blockchain)

        return NEARWalletManager(
            wallet: input.wallet,
            networkService: networkService,
            transactionBuilder: transactionBuilder,
            protocolConfigCache: .shared
        )
    }

    private func baseURLs(for blockchain: Blockchain, with sdkConfig: BlockchainSdkConfig) -> [URL] {
        var baseURLStrings: [String] = []

        if blockchain.isTestnet {
            baseURLStrings.append(
                contentsOf: [
                    "https://rpc.testnet.near.org",
                ]
            )
        } else {
            baseURLStrings.append(
                contentsOf: [
                    "https://rpc.mainnet.near.org",
                    "https://near.nownodes.io/\(sdkConfig.nowNodesApiKey)",
                    "https://near.getblock.io/\(sdkConfig.getBlockApiKey)",
                    "https://near-mainnet.infura.io/v3/\(sdkConfig.infuraProjectId)",
                ]
            )
        }

        return baseURLStrings
            .map { URL(string: $0)! }
    }
}
