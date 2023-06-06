//
//  TezosWalletAssembly.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 08.02.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BitcoinCore

struct TezosWalletAssembly: WalletManagerAssembly {
    
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        return try TezosWalletManager(wallet: input.wallet).then {
            $0.txBuilder = try TezosTransactionBuilder(walletPublicKey: input.wallet.publicKey.blockchainKey, curve: input.blockchain.curve)
            $0.networkService = TezosNetworkService(
                providers: TezosApi.makeAllProviders(configuration: input.networkConfig), exceptionHandler: input.exceptionHandler
            )
        }
    }
    
}
