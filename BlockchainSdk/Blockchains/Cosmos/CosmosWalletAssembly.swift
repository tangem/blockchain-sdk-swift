//
//  CosmosWalletAssembly.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 13.04.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct CosmosWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        let blockchain = input.blockchain
        let cosmosChain: CosmosChain
        switch blockchain {
        case .cosmos(let testnet):
            cosmosChain = .cosmos(testnet: testnet)
        case .terraV1:
            cosmosChain = .terraV1
        case .terraV2:
            cosmosChain = .terraV2
        default:
            throw WalletError.empty
        }

        let config = input.blockchainSdkConfig
        let linkResolver = APILinkResolver(blockchain: blockchain, config: config)

        let providers: [CosmosRestProvider]
        if blockchain.isTestnet {
            providers = TestnetAPIURLProvider(blockchain: blockchain).urls()?.map {
                CosmosRestProvider(url: $0.url.absoluteString, configuration: input.networkConfig)
            } ?? []
        } else {
            providers = input.apiInfo.compactMap {
                guard let link = linkResolver.resolve(for: $0) else {
                    return nil
                }

                return CosmosRestProvider(url: link, configuration: input.networkConfig)
            }
        }
        let networkService = CosmosNetworkService(cosmosChain: cosmosChain, providers: providers)
        let publicKey = try Secp256k1Key(with: input.wallet.publicKey.blockchainKey).compress()
        
        let walletManager = try CosmosWalletManager(cosmosChain: cosmosChain, wallet: input.wallet).then {
            $0.txBuilder = try CosmosTransactionBuilder(publicKey: publicKey, cosmosChain: cosmosChain)
            $0.networkService = networkService
        }
        
        return walletManager
    }
}
