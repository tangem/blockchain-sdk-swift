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
        let urls = [
            URL(string: "wss://electrum.nexa.org:20004")!,
            URL(string: "wss://onekey-electrum.bitcoinunlimited.info:20004")!,
        ]

        let provider = ElectrumNetworkProvider(
            providers: urls.map { ElectrumWebSocketManager(url: $0) },
            decimalValue: input.blockchain.decimalValue
        )
        let transactionBuilder = NexaTransactionBuilder()
        
        return NexaWalletManager(
            wallet: input.wallet,
            transactionBuilder: transactionBuilder,
            networkProvider: provider
        )
    }
}
