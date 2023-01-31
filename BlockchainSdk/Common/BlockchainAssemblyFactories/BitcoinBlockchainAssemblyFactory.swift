//
//  BitcoinBlockchainAssemblyFactory.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 31.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import stellarsdk
import BitcoinCore
import Solana_Swift

struct BitcoinBlockchainAssemblyFactory: BlockchainAssemblyFactoryProtocol {
    
    func canAssembly(blockchain: Blockchain, isTestnet: Bool = false) -> Bool {
        return blockchain == .ton(testnet: isTestnet)
    }
    
    func assembly(with input: BlockchainAssemblyFactoryInput, isTestnet: Bool = false) throws -> AssemblyWallet {
        return try BitcoinWalletManager(wallet: input.wallet).then {
            let network: BitcoinNetwork = isTestnet ? .testnet : .mainnet
            let bitcoinManager = BitcoinManager(networkParams: network.networkParams,
                                                walletPublicKey: input.wallet.publicKey.blockchainKey,
                                                compressedWalletPublicKey: try Secp256k1Key(with: input.wallet.publicKey.blockchainKey).compress(),
                                                bip: input.pairPublicKey == nil ? .bip84 : .bip141)
            
            $0.txBuilder = BitcoinTransactionBuilder(bitcoinManager: bitcoinManager, addresses: input.wallet.addresses)
            
            var providers = [AnyBitcoinNetworkProvider]()
            
            providers.append(BlockBookUtxoProvider(blockchain: input.blockchain,
                                                   blockBookConfig: NowNodesBlockBookConfig(apiKey: input.blockchainConfig.nowNodesApiKey),
                                                   networkConfiguration: input.networkConfig)
                .eraseToAnyBitcoinNetworkProvider())
            
            if !isTestnet {
                providers.append(BlockBookUtxoProvider(blockchain: input.blockchain,
                                                       blockBookConfig: GetBlockBlockBookConfig(apiKey: input.blockchainConfig.getBlockApiKey),
                                                       networkConfiguration: input.networkConfig)
                    .eraseToAnyBitcoinNetworkProvider())
                
                providers.append(BlockchainInfoNetworkProvider(configuration: input.networkConfig)
                    .eraseToAnyBitcoinNetworkProvider())
            }
            
            providers.append(contentsOf: makeBlockchairNetworkProviders(for: .bitcoin(testnet: isTestnet),
                                                                        configuration: input.networkConfig,
                                                                        apiKeys: input.blockchainConfig.blockchairApiKeys))
            
            providers.append(BlockcypherNetworkProvider(endpoint: .bitcoin(testnet: isTestnet),
                                                        tokens: input.blockchainConfig.blockcypherTokens,
                                                        configuration: input.networkConfig)
                .eraseToAnyBitcoinNetworkProvider())
            
            $0.networkService = BitcoinNetworkService(providers: providers)
        }
    }
    
    private func makeBlockchairNetworkProviders(for endpoint: BlockchairEndpoint, configuration: NetworkProviderConfiguration, apiKeys: [String]) -> [AnyBitcoinNetworkProvider] {
        let apiKeys: [String?] = [nil] + apiKeys
        
        let providers = apiKeys.map {
            BlockchairNetworkProvider(endpoint: endpoint, apiKey: $0, configuration: configuration)
                .eraseToAnyBitcoinNetworkProvider()
        }
        
        return providers
    }
    
}
