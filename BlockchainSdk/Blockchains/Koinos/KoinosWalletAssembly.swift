//
//  KoinosWalletAssembly.swift
//  BlockchainSdk
//
//  Created by Aleksei Muraveinik on 06.05.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import TangemSdk

struct KoinosWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        let blockchain = input.blockchain
        let isTestnet = blockchain.isTestnet
        let koinContractAbi = KoinContractAbi(
            isTestnet: isTestnet,
            decimalCount: blockchain.decimalCount
        )
        
        return KoinosWalletManager(
            wallet: input.wallet,
            networkService: KoinosNetworkService(
                providers: APIResolver(blockchain: blockchain, config: input.blockchainSdkConfig)
                    .resolveProviders(apiInfos: input.apiInfo) { nodeInfo, _ in
                        KoinosNetworkProvider(
                            node: nodeInfo,
                            koinContractAbi: koinContractAbi,
                            configuration: input.networkConfig
                        )
                    }
            ),
            transactionBuilder: KoinosTransactionBuilder(koinContractAbi: koinContractAbi)
        )
    }
}
