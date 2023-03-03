//
//  EthereumChildWalletAssembly.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 08.02.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import stellarsdk
import BitcoinCore

struct EthereumWalletAssembly: WalletAssemblyProtocol {
    
    static func make(with input: BlockchainAssemblyInput) throws -> AssemblyWallet {
        let manager: EthereumWalletManager
        let endpoints = input.blockchain.getJsonRpcEndpoints(
            keys: EthereumApiKeys(
                infuraProjectId: input.blockchainConfig.infuraProjectId,
                nowNodesApiKey: input.blockchainConfig.nowNodesApiKey,
                getBlockApiKey: input.blockchainConfig.getBlockApiKey,
                quickNodeBscCredentials: input.blockchainConfig.quickNodeBscCredentials
            )
        )!
        
        if case .optimism = input.blockchain {
            manager = OptimismWalletManager(wallet: input.wallet, rpcURL: endpoints[0])
        } else {
            manager = EthereumWalletManager(wallet: input.wallet)
        }
        
        let blockcypherProvider: BlockcypherNetworkProvider?
        
        if case .ethereum = input.blockchain {
            blockcypherProvider = BlockcypherNetworkProvider(
                endpoint: .ethereum,
                tokens: input.blockchainConfig.blockcypherTokens,
                configuration: input.networkConfig
            )
        } else {
            blockcypherProvider = nil
        }
        
        // TODO: Move this generation into assembly.
        var transactionHistoryProvider: TransactionHistoryProvider?
        if input.blockchain.canLoadTransactionHistory {
            // This should be decided by each assembly
            transactionHistoryProvider = BlockscoutNetworkProvider(configuration: .init(credentials: input.blockchainConfig.blockscoutCredentials))
        }
        
        return try manager.then {
            let chainId = input.blockchain.chainId!
            
            let jsonRpcProviders = endpoints.map {
                return EthereumJsonRpcProvider(
                    url: $0,
                    configuration: input.networkConfig
                )
            }
            
            $0.txBuilder = try EthereumTransactionBuilder(walletPublicKey: input.wallet.publicKey.blockchainKey, chainId: chainId)
            $0.networkService = EthereumNetworkService(decimals: input.blockchain.decimalCount,
                                                       providers: jsonRpcProviders,
                                                       blockcypherProvider: blockcypherProvider,
                                                       blockchairProvider: nil, // TODO: TBD Do we need the TokenFinder feature?
                                                       transactionHistoryProvider: transactionHistoryProvider)
        }
    }
    
}
