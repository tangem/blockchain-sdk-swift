//
//  RadiantWalletAssembly.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 05.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct RadiantWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        let socketManagers: [ElectrumWebSocketManager] = RadiantNetworkEndpoint.allCases.map {
            .init(url: URL(string: $0.urlString)!)
        }

        let transactionBuilder = RadiantTransactionBuilder(
            coinType: .bitcoinCash,
            publicKey: input.wallet.publicKey.blockchainKey,
            decimalValue: Decimal(input.wallet.blockchain.decimalCount),
            walletAddress: input.wallet.address
        )
        
        return try RadiantWalletManager(
            wallet: input.wallet,
            transactionBuilder: transactionBuilder,
            networkService: RadiantNetworkService(
                electrumProvider: .init(
                    providers: socketManagers,
                    decimalValue: input.blockchain.decimalValue
                )
            )
        )
    }
}
