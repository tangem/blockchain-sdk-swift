//
//  SolanaWalletAssembly.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 08.02.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import Solana_Swift

struct SolanaWalletAssembly: WalletManagerAssembly {
    
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        return SolanaWalletManager(wallet: input.wallet).then {
            let endpoints: [RPCEndpoint]
            if input.blockchain.isTestnet {
                endpoints = [
                    .devnetSolana,
                    .devnetGenesysGo,
                ]
            } else {
                endpoints = [
                    .nowNodes(apiKey: input.blockchainSdkConfig.nowNodesApiKey),
                    .quiknode(
                        apiKey: input.blockchainSdkConfig.quickNodeSolanaCredentials.apiKey,
                        subdomain: input.blockchainSdkConfig.quickNodeSolanaCredentials.subdomain
                    ),
                    .mainnetBetaSolana,
                ]
            }
            
            let apiLogger = SolanaApiLoggerUtil()
            let networkRouter = NetworkingRouter(endpoints: endpoints, apiLogger: apiLogger)
            let accountStorage = SolanaDummyAccountStorage()
            
            $0.solanaSdk = Solana(router: networkRouter, accountStorage: accountStorage)
            $0.networkService = SolanaNetworkService(solanaSdk: $0.solanaSdk, blockchain: input.blockchain, hostProvider: networkRouter)
        }
    }
    
}
