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
        let endpoints = networkProviderAssembly.makeJsonRpcEndpoints(with: input)
        
        return try OptimismWalletManager(
            wallet: input.wallet,
            rpcURL: endpoints[0]
        ).then {
            let chainId = input.blockchain.chainId!
            
            $0.txBuilder = try EthereumTransactionBuilder(walletPublicKey: input.wallet.publicKey.blockchainKey, chainId: chainId)
            $0.networkService = EthereumNetworkService(
                decimals: input.blockchain.decimalCount,
                providers: EthereumJsonRpcProvider.make(from: endpoints, with: input.networkConfig),
                blockcypherProvider: nil,
                blockchairProvider: nil, // TODO: TBD Do we need the TokenFinder feature?
                transactionHistoryProvider: networkProviderAssembly.makeBlockscoutNetworkProvider(
                    canLoad: input.blockchain.canLoadTransactionHistory,
                    with: input
                )
            )
        }
    }
    
}
