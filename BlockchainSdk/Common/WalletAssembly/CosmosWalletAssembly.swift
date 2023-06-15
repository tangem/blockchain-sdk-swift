//
//  CosmosWalletAssembly.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 13.04.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct CosmosWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        let cosmosChain: CosmosChain
        switch input.blockchain {
        case .cosmos(let testnet):
            cosmosChain = .cosmos(testnet: testnet)
        case .terraV1:
            cosmosChain = .terraV1
        case .terraV2:
            cosmosChain = .terraV2
        default:
            throw WalletError.empty
        }
        
        let urls = cosmosChain.urls(for: input.blockchainConfig)
        let providers = urls.map {
            CosmosRestProvider(url: $0, configuration: input.networkConfig)
        }
        let networkService = CosmosNetworkService(blockchain: input.blockchain, cosmosChain: cosmosChain, providers: providers)
        
        let walletManager = CosmosWalletManager(cosmosChain: cosmosChain, wallet: input.wallet).then {
            $0.txBuilder = CosmosTransactionBuilder(wallet: input.wallet, cosmosChain: cosmosChain)
            $0.networkService = networkService
        }
        
        return walletManager
    }
}
