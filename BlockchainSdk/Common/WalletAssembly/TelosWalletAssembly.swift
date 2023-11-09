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
        return try TelosWalletManager(wallet: input.wallet).then {
            let chainId = input.blockchain.chainId!
            
            $0.txBuilder = try EthereumTransactionBuilder(walletPublicKey: input.wallet.publicKey.blockchainKey, chainId: chainId)
            $0.networkService = EthereumNetworkService(
                decimals: input.blockchain.decimalCount,
                providers: networkProviderAssembly.makeEthereumJsonRpcProviders(with: input),
                blockcypherProvider: nil,
                abiEncoder: WalletCoreABIEncoder()
            )
        }
    }
    
}
