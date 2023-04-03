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
            let tronGridNetworks: [TronNetwork]
            
            if !input.blockchain.isTestnet {
                tronGridNetworks = [
                    .tronGrid(apiKey: nil),
                    .tronGrid(apiKey: input.blockchainConfig.tronGridApiKey),
                ]
            } else {
                tronGridNetworks = [.nile]
            }
            
            var providers: [TronJsonRpcProvider] = []
            
            if !input.blockchain.isTestnet {
                providers = [
                    TronJsonRpcProvider(
                        network: .nowNodes(apiKey: input.blockchainConfig.nowNodesApiKey),
                        configuration: input.networkConfig
                    ),
                    TronJsonRpcProvider(
                        network: .getBlock(apiKey: input.blockchainConfig.getBlockApiKey),
                        configuration: input.networkConfig
                    ),
                ]
            }
            
            providers.append(contentsOf: tronGridNetworks.map {
                TronJsonRpcProvider(
                    network: $0,
                    configuration: input.networkConfig
                )
            })
            $0.networkService = TronNetworkService(isTestnet: input.blockchain.isTestnet, providers: providers)
            $0.txBuilder = TronTransactionBuilder(blockchain: input.blockchain)
        }
    }
}
