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
        let providers = [
            AlgorandNetworkProvider(
                node: .init(
                    type: .nownodes,
                    apiKeyValue: input.blockchainSdkConfig.nowNodesApiKey
                ),
                networkConfig: input.networkConfig
            ),
            AlgorandNetworkProvider(
                node: .init(
                    type: .getblock,
                    apiKeyValue: input.blockchainSdkConfig.getBlockCredentials.credential(for: input.blockchain, type: .rest)
                ),
                networkConfig: input.networkConfig
            )
        ]

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
