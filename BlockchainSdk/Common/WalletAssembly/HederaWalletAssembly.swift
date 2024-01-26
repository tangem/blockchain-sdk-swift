//
//  HederaWalletAssembly.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 25.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct HederaWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        let networkService = HederaNetworkService()
        let transactionBuilder = HederaTransactionBuilder()

        return HederaWalletManager(
            wallet: input.wallet,
            networkService: networkService,
            transactionBuilder: transactionBuilder
        )
    }
}
