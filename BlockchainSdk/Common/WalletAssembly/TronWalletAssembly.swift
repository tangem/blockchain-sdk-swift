//
//  TronWalletAssembly.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 08.02.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct TronWalletAssembly: WalletManagerAssembly {
    
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        return TronWalletManager(wallet: input.wallet).then {
            let tronGridNetwork: TronNetwork = input.blockchain.isTestnet ? .nile : .mainnet
            
            var providers: [TronJsonRpcProvider] = []
            
            if !input.blockchain.isTestnet {
                providers = [
                    TronJsonRpcProvider(
                        network: .nowNodes(apiKey: input.blockchainConfig.nowNodesApiKey),
                        apiKeyValue: nil,
                        configuration: input.networkConfig
                    ),
                    TronJsonRpcProvider(
                        network: .getBlock(apiKey: input.blockchainConfig.getBlockApiKey),
                        apiKeyValue: nil,
                        configuration: input.networkConfig
                    ),
                ]
            }
            
            providers.append(contentsOf: [
                TronJsonRpcProvider(
                    network: tronGridNetwork,
                    apiKeyValue: nil,
                    configuration: input.networkConfig
                ),
                TronJsonRpcProvider(
                    network: tronGridNetwork,
                    apiKeyValue: input.blockchainConfig.tronGridApiKey,
                    configuration: input.networkConfig
                ),
            ])
            $0.networkService = TronNetworkService(isTestnet: input.blockchain.isTestnet, providers: providers)
            $0.txBuilder = TronTransactionBuilder(blockchain: input.blockchain)
        }
    }
    
}
