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
        let txBuilder = AptosTransactionBuilder(
            publicKey: input.wallet.publicKey.blockchainKey,
            isTestnet: input.blockchain.isTestnet,
            decimalValue: input.blockchain.decimalValue
        )
        
        return AptosWalletManager(wallet: input.wallet, transactionBuilder: txBuilder)
    }
}
