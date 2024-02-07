//
//  AptosWalletAssembly.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 25.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct AptosWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        let chainId: AptosChainId = input.blockchain.isTestnet ? .testnet : .mainnet
        
        let txBuilder = AptosTransactionBuilder(
            publicKey: input.wallet.publicKey.blockchainKey,
            decimalValue: input.blockchain.decimalValue,
            chainId: chainId
        )
        
        return AptosWalletManager(wallet: input.wallet, transactionBuilder: txBuilder)
    }
}
