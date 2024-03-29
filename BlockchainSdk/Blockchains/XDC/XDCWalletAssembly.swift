//
//  XDCWalletAssembly.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 17.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct XDCWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        return try EthereumWalletManager(wallet: input.wallet).then {
            let chainId = input.blockchain.chainId!

            $0.txBuilder = try XDCTransactionBuilder(walletPublicKey: input.wallet.publicKey.blockchainKey, chainId: chainId)
            $0.networkService = XDCNetworkService(
                decimals: input.blockchain.decimalCount,
                providers: networkProviderAssembly.makeEthereumJsonRpcProviders(with: input),
                blockcypherProvider: nil,
                abiEncoder: WalletCoreABIEncoder()
            )
        }
    }
}
