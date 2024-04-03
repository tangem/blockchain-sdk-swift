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
            let providers: [TronJsonRpcProvider]
            let config = input.blockchainSdkConfig
            let blockchain = input.blockchain
            let linkResolver = APILinkResolver(blockchain: blockchain, config: config)
            let apiKeysInfoProvider = APIKeysInfoProvider(blockchain: blockchain, config: config)

            providers = input.apiInfo.compactMap {
                guard
                    let link = linkResolver.resolve(for: $0),
                    let url = URL(string: link)
                else {
                    return nil
                }

                let apiKeyInfo: APIKeyInfo? = apiKeysInfoProvider.apiKeys(for: $0.api)
                return TronJsonRpcProvider(
                    node: .init(url: url, apiKeyInfo: apiKeyInfo),
                    configuration: input.networkConfig
                )
            }
            
            $0.networkService = TronNetworkService(isTestnet: input.blockchain.isTestnet, providers: providers)
            $0.txBuilder = TronTransactionBuilder(blockchain: input.blockchain)
        }
    }
}
