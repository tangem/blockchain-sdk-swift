//
//  ICPWalletAssembly.swift
//  BlockchainSdk
//
//  Created by Dmitry Fedorov on 12.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct ICPWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> any WalletManager {
        let blockchain = input.blockchain
        let config = input.blockchainSdkConfig
        
        let providers: [ICPProvider] = [ICPProvider(node: NodeInfo(url: URL(string: "https://icp-api.io/")!), networkConfig: input.networkConfig)]

//        let providers: [ICPProvider] = APIResolver(blockchain: blockchain, config: config)
//            .resolveProviders(apiInfos: input.apiInfo) { nodeInfo, _ in
//                ICPProvider(node: nodeInfo, networkConfig: input.networkConfig)
//            }
        
        return ICPWalletManager(
            wallet: input.wallet,
            networkService: ICPNetworkService(
                providers: providers,
                blockchain: input.blockchain
            )
        )
    }
}
