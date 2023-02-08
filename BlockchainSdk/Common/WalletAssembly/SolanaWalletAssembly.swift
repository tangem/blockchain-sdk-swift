//
//  SolanaWalletAssembly.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 08.02.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import stellarsdk
import BitcoinCore
import Solana_Swift

struct SolanaWalletAssembly: BlockchainAssemblyProtocol {
    
    static func canAssembly(blockchain: Blockchain) -> Bool {
        blockchain == .solana(testnet: blockchain.isTestnet)
    }
    
    static func assembly(with input: BlockchainAssemblyInput) throws -> AssemblyWallet {
        return SolanaWalletManager(wallet: input.wallet).then {
            let endpoints: [Solana_Swift.RPCEndpoint]
            if input.blockchain.isTestnet {
                endpoints = [
                    .devnetSolana,
                    .devnetGenesysGo,
                ]
            } else {
                endpoints = [
                    .nowNodes(apiKey: input.blockchainConfig.nowNodesApiKey),
                    .getBlock(apiKey: input.blockchainConfig.getBlockApiKey),
                    .quiknode(
                        apiKey: input.blockchainConfig.quickNodeSolanaCredentials.apiKey,
                        subdomain: input.blockchainConfig.quickNodeSolanaCredentials.subdomain
                    ),
                    .ankr,
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
