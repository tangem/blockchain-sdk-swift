//
//  DecimalWalletAssembly.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 15.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct DecimalWalletAssembly: WalletManagerAssembly {
    
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        return try DecimalWalletManager(wallet: input.wallet).then {
            let chainId = input.blockchain.chainId!
            
            $0.txBuilder = try DecimalTransactionBuilder(walletPublicKey: input.wallet.publicKey.blockchainKey, chainId: chainId)
            $0.networkService = EthereumNetworkService(
                decimals: input.blockchain.decimalCount,
                providers: networkProviderAssembly.makeEthereumJsonRpcProviders(with: input),
                blockcypherProvider: nil,
                abiEncoder: WalletCoreABIEncoder()
            )
        }
    }
    
}
