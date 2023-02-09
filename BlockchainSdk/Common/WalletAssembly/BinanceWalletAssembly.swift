//
//  BinanceWalletAssembly.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 08.02.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct BinanceWalletAssembly: WalletAssemblyProtocol {
    
    static func make(with input: BlockchainAssemblyInput) throws -> AssemblyWallet {
        return try BinanceWalletManager(wallet: input.wallet).then {
            $0.txBuilder = try BinanceTransactionBuilder(walletPublicKey: input.wallet.publicKey.blockchainKey, isTestnet: input.blockchain.isTestnet)
            $0.networkService = BinanceNetworkService(isTestNet: input.blockchain.isTestnet)
        }
    }
    
}
