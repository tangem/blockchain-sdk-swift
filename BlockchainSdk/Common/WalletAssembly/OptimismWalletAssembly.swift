//
//  OptiomizmWalletAssembly.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 20.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct OptimismWalletAssembly: WalletManagerAssembly {
    
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        let manager: EthereumWalletManager
        let endpoints = input.blockchain.getJsonRpcEndpoints(
            keys: EthereumApiKeys(
                infuraProjectId: input.blockchainConfig.infuraProjectId,
                nowNodesApiKey: input.blockchainConfig.nowNodesApiKey,
                getBlockApiKey: input.blockchainConfig.getBlockApiKey,
                quickNodeBscCredentials: input.blockchainConfig.quickNodeBscCredentials
            )
        )!
        
        manager = OptimismWalletManager(wallet: input.wallet, rpcURL: endpoints[0])
        
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
                                                       blockcypherProvider: nil,
                                                       blockchairProvider: nil, // TODO: TBD Do we need the TokenFinder feature?
                                                       transactionHistoryProvider: transactionHistoryProvider)
        }
    }
    
}
