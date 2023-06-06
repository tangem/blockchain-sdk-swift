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
            let networks: [TronNetwork]
            
            if !input.blockchain.isTestnet {
                networks = [
                    .tronGrid(apiKey: nil),
                    .tronGrid(apiKey: input.blockchainConfig.tronGridApiKey),
                    .nowNodes(apiKey: input.blockchainConfig.nowNodesApiKey),
                    .getBlock(apiKey: input.blockchainConfig.getBlockApiKey),
                ]
            } else {
                networks = [
                    .nile,
                ]
            }
            
            let providers: [TronJsonRpcProvider] = networks.map {
                TronJsonRpcProvider(
                    network: $0,
                    configuration: input.networkConfig
                )
            }
            $0.networkService = TronNetworkService(isTestnet: input.blockchain.isTestnet, providers: providers, exceptionHandler: input.exceptionHandler)
            $0.txBuilder = TronTransactionBuilder(blockchain: input.blockchain)
        }
    }
}
