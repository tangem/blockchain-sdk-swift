//
//  KusumaWalletAssembly.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 08.02.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct SubstrateWalletAssembly: WalletManagerAssembly {
    
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        guard let network = PolkadotNetwork(blockchain: input.blockchain) else {
            throw WalletError.empty
        }
        
        return PolkadotWalletManager(network: network, wallet: input.wallet).then {
            let blockchain = input.blockchain
            let networkConfig = input.networkConfig
            let providers: [PolkadotJsonRpcProvider] = APIResolver(blockchain: blockchain, config: input.blockchainSdkConfig)
                .resolveProviders(apiInfos: input.apiInfo) { nodeInfo, _ in
                    PolkadotJsonRpcProvider(url: nodeInfo.url, configuration: networkConfig)
                }
            
            $0.networkService = PolkadotNetworkService(providers: providers, network: network)
            $0.txBuilder = PolkadotTransactionBuilder(blockchain: input.blockchain, walletPublicKey: input.wallet.publicKey.blockchainKey, network: network)
        }
    }
}
