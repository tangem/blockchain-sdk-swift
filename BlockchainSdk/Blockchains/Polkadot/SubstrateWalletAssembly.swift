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
            var providers: [PolkadotJsonRpcProvider] = APIResolver(blockchain: blockchain, config: input.blockchainSdkConfig)
                .resolveProviders(apiInfos: input.apiInfo) { nodeInfo, _ in
                    PolkadotJsonRpcProvider(node: nodeInfo, configuration: networkConfig)
                }
            
            if case .bittensor = network {
                let dwellirResolver = DwellirAPIResolver(config: input.blockchainSdkConfig)
                
                if let dwellirNodeInfo = dwellirResolver.resolve() {
                    providers.append(PolkadotJsonRpcProvider(node: dwellirNodeInfo, configuration: networkConfig))
                }
                
                let onfinalityResolver = OnfinalityAPIResolver(config: input.blockchainSdkConfig)
                
                if let onfinalityNodeInfo = onfinalityResolver.resolve() {
                    providers.append(PolkadotJsonRpcProvider(node: onfinalityNodeInfo, configuration: networkConfig))
                }
            }
            
            $0.networkService = PolkadotNetworkService(providers: providers, network: network)
            $0.txBuilder = PolkadotTransactionBuilder(blockchain: input.blockchain, walletPublicKey: input.wallet.publicKey.blockchainKey, network: network)
        }
    }
}
