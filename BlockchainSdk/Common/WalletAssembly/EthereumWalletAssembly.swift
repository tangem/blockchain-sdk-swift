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

struct EthereumWalletAssembly: WalletManagerAssembly {
    
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        let endpoints = networkProviderAssembly.makeJsonRpcEndpoints(with: input)
        
        return try EthereumWalletManager(wallet: input.wallet).then {
            let chainId = input.blockchain.chainId!
            
            $0.txBuilder = try EthereumTransactionBuilder(walletPublicKey: input.wallet.publicKey.blockchainKey, chainId: chainId)
            $0.networkService = EthereumNetworkService(
                decimals: input.blockchain.decimalCount,
                providers: EthereumJsonRpcProvider.make(from: endpoints, with: input.networkConfig),
                blockcypherProvider: networkProviderAssembly.makeBlockcypherNetworkProvider(endpoint: .ethereum, with: input),
                blockchairProvider: nil, // TODO: TBD Do we need the TokenFinder feature?
                transactionHistoryProvider: networkProviderAssembly.makeBlockscoutNetworkProvider(
                    canLoad: input.blockchain.canLoadTransactionHistory,
                    with: input
                )
            )
        }
    }
    
}
