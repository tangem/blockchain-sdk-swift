//
//  RadiantWalletAssembly.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 05.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct RadiantWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        let socketManagers: [ElectrumWebSocketManager] = RadiantNetworkEndpoint.allCases.map {
            .init(url: URL(string: $0.urlString)!)
        }
        
        let publicKey = try Secp256k1Key(with: input.wallet.publicKey.blockchainKey).compress()
        
        let transactionBuilder = try RadiantCashTransactionBuilder(
            walletPublicKey: publicKey,
            decimalValue: input.blockchain.decimalValue
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
