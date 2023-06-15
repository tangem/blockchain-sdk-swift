//
//  TONWalletAssembly.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 17.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BitcoinCore

struct TONWalletAssembly: WalletManagerAssembly {
    
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        var providers: [TONProvider] = []
        
        providers.append(
            TONProvider(
                node: .init(
                    apiKeyValue: input.blockchainConfig.tonCenterApiKeys.getApiKey(for: input.blockchain.isTestnet),
                    endpointType: .toncenter(input.blockchain.isTestnet)
                ),
                networkConfig: input.networkConfig
            )
        )
        
        if !input.blockchain.isTestnet {
            providers.append(
                contentsOf: [
                    TONProvider(
                        node: .init(
                            apiKeyValue: input.blockchainConfig.nowNodesApiKey,
                            endpointType: .nownodes
                        ),
                        networkConfig: input.networkConfig
                    ),
                    TONProvider(
                        node: .init(
                            apiKeyValue: input.blockchainConfig.getBlockApiKey,
                            endpointType: .getblock
                        ),
                        networkConfig: input.networkConfig
                    )
                ]
            )
        }
        
        return try TONWalletManager(
            wallet: input.wallet,
            networkService: .init(
                blockchain: input.blockchain,
                providers: providers
            )
        )
    }
    
}
