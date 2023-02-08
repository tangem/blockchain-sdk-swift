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

struct DashWalletAssembly: BlockchainAssemblyProtocol {
    
    func assembly(with input: BlockchainAssemblyInput) throws -> AssemblyWallet {
        try DashWalletManager(wallet: input.wallet).then {
            let compressed = try Secp256k1Key(with: input.wallet.publicKey.blockchainKey).compress()
            
            let bitcoinManager = BitcoinManager(
                networkParams: input.blockchain.isTestnet ? DashTestNetworkParams() : DashMainNetworkParams(),
                walletPublicKey: input.wallet.publicKey.blockchainKey,
                compressedWalletPublicKey: compressed,
                bip: .bip44
            )
            
            // TODO: Add CryptoAPIs for testnet
            
            $0.txBuilder = BitcoinTransactionBuilder(bitcoinManager: bitcoinManager, addresses: input.wallet.addresses)
            
            var providers: [AnyBitcoinNetworkProvider] = []
            
            providers.append(BlockBookUtxoProvider(blockchain: .dash(testnet: input.blockchain.isTestnet),
                                                   blockBookConfig: NowNodesBlockBookConfig(apiKey: input.blockchainConfig.nowNodesApiKey),
                                                   networkConfiguration: input.networkConfig)
                .eraseToAnyBitcoinNetworkProvider())
            
            providers.append(BlockBookUtxoProvider(blockchain: .dash(testnet: input.blockchain.isTestnet),
                                                   blockBookConfig: GetBlockBlockBookConfig(apiKey: input.blockchainConfig.getBlockApiKey),
                                                   networkConfiguration: input.networkConfig)
                .eraseToAnyBitcoinNetworkProvider())
            
            providers.append(contentsOf: makeBlockchairNetworkProviders(for: .dash,
                                                                        configuration: input.networkConfig,
                                                                        apiKeys: input.blockchainConfig.blockchairApiKeys))
            
            providers.append(BlockcypherNetworkProvider(endpoint: .dash,
                                                        tokens: input.blockchainConfig.blockcypherTokens,
                                                        configuration: input.networkConfig)
                .eraseToAnyBitcoinNetworkProvider())
            
            $0.networkService = BitcoinNetworkService(providers: providers)
        }
    }
    
}
