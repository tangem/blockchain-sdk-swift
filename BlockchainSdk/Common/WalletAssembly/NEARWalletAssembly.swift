//
//  NEARWalletAssembly.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 12.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct NEARWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        // TODO: Andrey Fedorov - Add actual implementation (IOS-4070)
        let blockchain = input.blockchain
        let networkProviders: [NEARNetworkProvider] = []
        let networkService = NEARNetworkService(blockchain: blockchain, providers: networkProviders)
        let transactionBuilder = NEARTransactionBuilder(blockchain: blockchain)

        return NEARWalletManager(
            wallet: input.wallet,
            networkService: networkService,
            transactionBuilder: transactionBuilder
        )
    }
}
