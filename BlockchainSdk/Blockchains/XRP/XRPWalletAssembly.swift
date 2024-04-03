//
//  XRPWalletAssembly.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 08.02.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct XRPWalletAssembly: WalletManagerAssembly {
    
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        return try XRPWalletManager(wallet: input.wallet).then {
            $0.txBuilder = try XRPTransactionBuilder(walletPublicKey: input.wallet.publicKey.blockchainKey, curve: input.blockchain.curve)

            let blockchain = input.blockchain
            let config = input.blockchainSdkConfig
            let linkResolver = APILinkResolver(blockchain: blockchain, config: config)
            let apiKeyInfoProvider = APIKeysInfoProvider(blockchain: blockchain, config: config)
            let providers: [XRPNetworkProvider] = input.apiInfo.compactMap {
                guard
                    let link = linkResolver.resolve(for: $0),
                    let url = URL(string: link)
                else {
                    return nil
                }

                let apiKeyInfo = apiKeyInfoProvider.apiKeys(for: $0.api)
                return XRPNetworkProvider(
                    node: .init(url: url, apiKeyInfo: apiKeyInfo),
                    configuration: input.networkConfig
                )
            }
            $0.networkService = XRPNetworkService(providers: providers)
//                providers: [
//                    XRPNetworkProvider(baseUrl: .xrpLedgerFoundation, configuration: input.networkConfig),
//                    XRPNetworkProvider(baseUrl: .nowNodes(apiKey: input.blockchainSdkConfig.nowNodesApiKey), configuration: input.networkConfig),
//                    XRPNetworkProvider(
//                        baseUrl: .getBlock(
//                            apiKey: input.blockchainSdkConfig.getBlockCredentials.credential(for: input.blockchain, type: .jsonRpc)
//                        ),
//                        configuration: input.networkConfig
//                    ),
//            ]
//            )
        }
    }
    
}
