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
        let blockchain = input.blockchain
        let config = input.blockchainSdkConfig

        let linkResolver = APILinkResolver(blockchain: blockchain, config: config)
        let apiKeyInfoProvider = APIKeysInfoProvider(blockchain: blockchain, config: config)
        let providers: [TONProvider] = input.apiInfo.compactMap {
            guard
                let link = linkResolver.resolve(for: $0),
                let url = URL(string: link)
            else {
                return nil
            }

            let apiKeyInfo = apiKeyInfoProvider.apiKeys(for: $0.api)
            return TONProvider(
                node: .init(url: url, apiKeyInfo: apiKeyInfo),
                networkConfig: input.networkConfig
            )
        }
        
        return try TONWalletManager(
            wallet: input.wallet,
            networkService: .init(
                providers: providers,
                blockchain: input.blockchain
            )
        )
    }
    
}
