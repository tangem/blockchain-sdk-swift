//
//  LitecoinWalletAssembly.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 08.02.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BitcoinCore

struct LitecoinWalletAssembly: WalletManagerAssembly {
    
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        return try LitecoinWalletManager(wallet: input.wallet).then {
            let bitcoinManager = BitcoinManager(networkParams: LitecoinNetworkParams(),
                                                walletPublicKey: input.wallet.publicKey.blockchainKey,
                                                compressedWalletPublicKey: try Secp256k1Key(with: input.wallet.publicKey.blockchainKey).compress(),
                                                bip: .bip84)
            
            $0.txBuilder = BitcoinTransactionBuilder(bitcoinManager: bitcoinManager, addresses: input.wallet.addresses)
            
            var providers = [AnyBitcoinNetworkProvider]()
            
            providers.append(
                networkProviderAssembly.makeBlockBookUtxoProvider(with: input, for: .nowNodes).eraseToAnyBitcoinNetworkProvider()
            )
            
            providers.append(
                networkProviderAssembly.makeBlockBookUtxoProvider(with: input, for: .getBlock).eraseToAnyBitcoinNetworkProvider()
            )
            
            providers.append(
                contentsOf: networkProviderAssembly.makeBlockchairNetworkProviders(endpoint: .litecoin, with: input)
            )
            
            providers.append(
                networkProviderAssembly.makeBlockcypherNetworkProvider(endpoint: .litecoin, with: input).eraseToAnyBitcoinNetworkProvider()
            )
            
            $0.networkService = LitecoinNetworkService(providers: providers)
        }
    }
    
}
