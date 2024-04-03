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
                                                walletPublicKey: input.wallet.publicKey.blockchainKey,
                                                compressedWalletPublicKey: try Secp256k1Key(with: input.wallet.publicKey.blockchainKey).compress(),
                                                bip: .bip44)
            
            $0.txBuilder = BitcoinTransactionBuilder(bitcoinManager: bitcoinManager, addresses: input.wallet.addresses)
            
            var providers = [AnyBitcoinNetworkProvider]()
            
            input.apiInfo.forEach {
                guard
                    $0.type == .private,
                    let api = $0.api
                else {
                    return
                }

                switch api {
                case .nownodes:
                    providers.append(networkProviderAssembly.makeBlockBookUtxoProvider(with: input, for: .nowNodes).eraseToAnyBitcoinNetworkProvider())
                case .getblock:
                    providers.append(networkProviderAssembly.makeBlockBookUtxoProvider(with: input, for: .getBlock).eraseToAnyBitcoinNetworkProvider())
                case .blockchair:
                    providers.append(contentsOf: networkProviderAssembly.makeBlockchairNetworkProviders(endpoint: .dogecoin, with: input))
                case .blockcypher:
                    providers.append(networkProviderAssembly.makeBlockcypherNetworkProvider(endpoint: .dogecoin, with: input).eraseToAnyBitcoinNetworkProvider())
                default:
                    return
                }
            }

            $0.networkService = BitcoinNetworkService(providers: providers)
        }
    }
    
}
