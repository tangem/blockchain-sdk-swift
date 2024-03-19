//
//  NexaWalletAssembly.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 19.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct NexaWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        let provider = NexaNetworkProvider(providers: [])
        let transactionBuilder = NexaTransactionBuilder()
        
        return NexaWalletManager(
            wallet: input.wallet,
            transactionBuilder: transactionBuilder,
            networkProvider: provider
        )
    }
}
