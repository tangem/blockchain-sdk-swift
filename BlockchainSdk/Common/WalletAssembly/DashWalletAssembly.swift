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
            
            if input.blockchainConfig.useBlockBookUtxoApis {
                providers.append(networkProviderAssembly.makeBlockBookUtxoProvider(with: input, for: .nowNodes).eraseToAnyBitcoinNetworkProvider())
                providers.append(networkProviderAssembly.makeBlockBookUtxoProvider(with: input, for: .getBlock).eraseToAnyBitcoinNetworkProvider())
            }
            
            providers.append(contentsOf: networkProviderAssembly.makeBlockchairNetworkProviders(endpoint: .dash, with: input))
            providers.append(networkProviderAssembly.makeBlockcypherNetworkProvider(endpoint: .dash, with: input).eraseToAnyBitcoinNetworkProvider())
            
            $0.networkService = BitcoinNetworkService(providers: providers)
        }
    }
    
}
