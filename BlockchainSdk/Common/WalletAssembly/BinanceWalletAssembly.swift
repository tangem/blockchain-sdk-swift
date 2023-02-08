//
//  BinanceWalletAssembly.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 08.02.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import stellarsdk
import BitcoinCore

struct BinanceWalletAssembly: BlockchainAssemblyProtocol {
    
    static func canAssembly(blockchain: Blockchain) -> Bool {
        blockchain == .binance(testnet: blockchain.isTestnet)
    }
    
    static func assembly(with input: BlockchainAssemblyInput) throws -> AssemblyWallet {
        return try BinanceWalletManager(wallet: input.wallet).then {
            $0.txBuilder = try BinanceTransactionBuilder(walletPublicKey: input.wallet.publicKey.blockchainKey, isTestnet: input.blockchain.isTestnet)
            $0.networkService = BinanceNetworkService(isTestNet: input.blockchain.isTestnet)
        }
    }
    
}
