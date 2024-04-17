//
//  DashWalletAssembly.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 08.02.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BitcoinCore

struct DashWalletAssembly: WalletManagerAssembly {
    
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        try DashWalletManager(wallet: input.wallet).then {
            let compressed = try Secp256k1Key(with: input.wallet.publicKey.blockchainKey).compress()
            
            let bitcoinManager = BitcoinManager(
                networkParams: input.blockchain.isTestnet ? DashTestNetworkParams() : DashMainNetworkParams(),
                walletPublicKey: input.wallet.publicKey.blockchainKey,
                compressedWalletPublicKey: compressed,
                bip: .bip44
            )
            
            $0.txBuilder = BitcoinTransactionBuilder(bitcoinManager: bitcoinManager, addresses: input.wallet.addresses)
            
            var providers: [AnyBitcoinNetworkProvider] = []
            
            input.apiInfo.forEach {
                switch $0 {
                case .nowNodes:
                    providers.append(networkProviderAssembly.makeBlockBookUtxoProvider(with: input, for: .nowNodes).eraseToAnyBitcoinNetworkProvider())
                case .blockchair:
                    providers.append(contentsOf: networkProviderAssembly.makeBlockchairNetworkProviders(endpoint: .dash, with: input))
                case .blockcypher:
                    providers.append(networkProviderAssembly.makeBlockcypherNetworkProvider(endpoint: .dash, with: input).eraseToAnyBitcoinNetworkProvider())
                default:
                    return
                }
            }
            
            $0.networkService = BitcoinNetworkService(providers: providers)
        }
    }
    
}
