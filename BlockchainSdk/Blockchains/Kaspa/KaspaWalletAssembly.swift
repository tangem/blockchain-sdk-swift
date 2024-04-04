//
//  KaspaWalletAssembly.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 21.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct KaspaWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        return KaspaWalletManager(wallet: input.wallet).then {
            $0.txBuilder = KaspaTransactionBuilder(blockchain: input.blockchain)
            
            let linkResolver = APINodeInfoResolver(blockchain: input.blockchain, config: input.blockchainSdkConfig)
            var providers: [KaspaNetworkProvider] = input.apiInfo.compactMap {
                guard  let nodeInfo = linkResolver.resolve(for: $0) else {
                    return nil
                }

                return KaspaNetworkProvider(url: nodeInfo.url, networkConfiguration: input.networkConfig)
            }
            
            if let kaspaSecondaryApiUrl = URL(string: input.blockchainSdkConfig.kaspaSecondaryApiUrl ?? "") {
                providers.append(
                    KaspaNetworkProvider(
                        url: kaspaSecondaryApiUrl,
                        networkConfiguration: input.networkConfig
                    )
                )
            }
            
            $0.networkService = KaspaNetworkService(providers: providers, blockchain: input.blockchain)
        }
    }
}
