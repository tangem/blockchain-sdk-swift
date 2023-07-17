//
//  ChiaWalletAssembly.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 10.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct ChiaWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        var providers: [ChiaNetworkProvider] = []
        
        providers.append(
            ChiaNetworkProvider(
                node: .init(
                    apiKeyValue: input.blockchainConfig.fireacademyApiKeys.getApiKey(for: input.blockchain.isTestnet),
                    endpointType: .fireacademy(isTestnet: input.blockchain.isTestnet)
                ),
                networkConfig: input.networkConfig
            )
        )
        
        return try ChiaWalletManager(
            wallet: input.wallet,
            networkService: .init(
                providers: providers,
                blockchain: input.blockchain
            ),
            txBuilder: .init()
        )
    }
}
