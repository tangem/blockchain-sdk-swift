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

struct SolanaWalletAssembly: WalletAssemblyProtocol {
    
    static func make(with input: BlockchainAssemblyInput) throws -> WalletAssembly {
        return SolanaWalletManager(wallet: input.wallet).then {
            let endpoints: [RPCEndpoint]
            if input.blockchain.isTestnet {
                endpoints = [
                    .devnetSolana,
                    .devnetGenesysGo,
                ]
            } else {
                endpoints = [
                    .nowNodes(apiKey: input.blockchainConfig.nowNodesApiKey),
                    .quiknode(
                        apiKey: input.blockchainConfig.quickNodeSolanaCredentials.apiKey,
                        subdomain: input.blockchainConfig.quickNodeSolanaCredentials.subdomain
                    ),
                    .mainnetBetaSolana,
                ]
            }
            
            let networkRouter = NetworkingRouter(endpoints: endpoints)
            let accountStorage = SolanaDummyAccountStorage()
            
            $0.solanaSdk = Solana(router: networkRouter, accountStorage: accountStorage)
            $0.networkService = SolanaNetworkService(solanaSdk: $0.solanaSdk, blockchain: input.blockchain, hostProvider: networkRouter)
        }
    }
    
}
