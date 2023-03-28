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
            
            var providers: [KaspaNetworkProvider] = [
                KaspaNetworkProvider(
                    url: URL(string: "https://api.kaspa.org")!,
                    blockchain: input.blockchain,
                    networkConfiguration: input.networkConfig
                ),
            ]
            
            if let kaspaSecondaryApiUrl = URL(string: input.blockchainConfig.kaspaSecondaryApiUrl ?? "") {
                providers.append(
                    KaspaNetworkProvider(
                        url: kaspaSecondaryApiUrl,
                        blockchain: input.blockchain,
                        networkConfiguration: input.networkConfig
                    )
                )
            }
            
            $0.networkService = KaspaNetworkService(providers: providers, blockchain: input.blockchain)
        }
    }
}
