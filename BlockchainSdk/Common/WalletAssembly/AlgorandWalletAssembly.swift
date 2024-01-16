//
//  AlgorandWalletAssembly.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 09.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct AlgorandWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        let transactionBuilder = AlgorandTransactionBuilder(isTestnet: input.blockchain.isTestnet)
        
        return AlgorandWalletManager(
            transactionBuilder: transactionBuilder,
            wallet: input.wallet
        )
    }
}
