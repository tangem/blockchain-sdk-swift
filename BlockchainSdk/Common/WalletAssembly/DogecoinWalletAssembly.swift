//
//  DogecoinAssembly.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 08.02.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BitcoinCore

struct DogecoinWalletAssembly: WalletManagerAssembly {
    
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        return try DogecoinWalletManager(wallet: input.wallet).then {
            let bitcoinManager = BitcoinManager(networkParams: DogecoinNetworkParams(),
                                                walletPublicKey: input.wallet.defaultPublicKey.blockchainKey,
                                                compressedWalletPublicKey: try Secp256k1Key(with: input.wallet.defaultPublicKey.blockchainKey).compress(),
                                                bip: .bip44)
            
            $0.txBuilder = BitcoinTransactionBuilder(bitcoinManager: bitcoinManager,
                                                     addresses: input.wallet.addresses.all.map { $0.address })
            
            var providers = [AnyBitcoinNetworkProvider]()
            
            providers.append(
                networkProviderAssembly.makeBlockBookUtxoProvider(with: input, for: .nowNodes).eraseToAnyBitcoinNetworkProvider()
            )
            
            providers.append(
                networkProviderAssembly.makeBlockBookUtxoProvider(with: input, for: .getBlock).eraseToAnyBitcoinNetworkProvider()
            )
            
            providers.append(
                contentsOf: networkProviderAssembly.makeBlockchairNetworkProviders(endpoint: .dogecoin, with: input)
            )
            
            providers.append(
                networkProviderAssembly.makeBlockcypherNetworkProvider(endpoint: .dogecoin, with: input).eraseToAnyBitcoinNetworkProvider()
            )
            
            $0.networkService = BitcoinNetworkService(providers: providers)
        }
    }
    
}
