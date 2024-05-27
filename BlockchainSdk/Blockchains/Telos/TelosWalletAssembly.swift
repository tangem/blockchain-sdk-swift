//
//  TelosWalletAssembly.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 09.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import stellarsdk
import BitcoinCore

struct TelosWalletAssembly: WalletManagerAssembly {
    
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        guard let chainId = input.blockchain.chainId else {
            throw EthereumWalletAssemblyError.chainIdNotFound
        }

        let txBuilder = EthereumTransactionBuilder(chainId: chainId)
        let networkService = EthereumNetworkService(
            decimals: input.blockchain.decimalCount,
            providers: networkProviderAssembly.makeEthereumJsonRpcProviders(with: input),
            blockcypherProvider: nil,
            abiEncoder: WalletCoreABIEncoder()
        )

        return TelosWalletManager(wallet: input.wallet, txBuilder: txBuilder, networkService: networkService)
    }
    
}
