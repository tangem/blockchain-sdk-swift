//
//  DogecoinAssembly.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 08.02.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import stellarsdk
import BitcoinCore

struct DogecoinWalletAssembly: BlockchainAssemblyProtocol {
    
    func assembly(with input: BlockchainAssemblyInput) throws -> AssemblyWallet {
        return try DogecoinWalletManager(wallet: input.wallet).then {
            let bitcoinManager = BitcoinManager(networkParams: DogecoinNetworkParams(),
                                                walletPublicKey: input.wallet.publicKey.blockchainKey,
                                                compressedWalletPublicKey: try Secp256k1Key(with: input.wallet.publicKey.blockchainKey).compress(),
                                                bip: .bip44)
            
            $0.txBuilder = BitcoinTransactionBuilder(bitcoinManager: bitcoinManager, addresses: input.wallet.addresses)
            
            var providers = [AnyBitcoinNetworkProvider]()
            
            providers.append(BlockBookUtxoProvider(blockchain: input.blockchain,
                                                   blockBookConfig: NowNodesBlockBookConfig(apiKey: input.blockchainConfig.nowNodesApiKey),
                                                   networkConfiguration: input.networkConfig)
                .eraseToAnyBitcoinNetworkProvider())
            
            providers.append(BlockBookUtxoProvider(blockchain: input.blockchain,
                                                   blockBookConfig: GetBlockBlockBookConfig(apiKey: input.blockchainConfig.getBlockApiKey),
                                                   networkConfiguration: input.networkConfig)
                .eraseToAnyBitcoinNetworkProvider())
            
            providers.append(contentsOf: makeBlockchairNetworkProviders(for: .dogecoin,
                                                                        configuration: input.networkConfig,
                                                                        apiKeys: input.blockchainConfig.blockchairApiKeys))
            
            providers.append(BlockcypherNetworkProvider(
                endpoint: .dogecoin,
                tokens: input.blockchainConfig.blockcypherTokens,
                configuration: input.networkConfig
            )
                .eraseToAnyBitcoinNetworkProvider())
            
            $0.networkService = BitcoinNetworkService(providers: providers)
        }
    }
    
}
