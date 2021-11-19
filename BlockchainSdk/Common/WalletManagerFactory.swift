//
//  WalletManagerFactory.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 06.12.2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import stellarsdk
import BitcoinCore

@available(iOS 13.0, *)
public class WalletManagerFactory {
    private let config: BlockchainSdkConfig
    
    public init(config: BlockchainSdkConfig) {
        self.config = config
    }
    
    /// Base wallet manager constructor
    /// - Parameters:
    ///   - card: Tangem card
    ///   - blockchain: blockhain to create. If nil, card native blockchain will be used
    /// - Returns: WalletManager?
    public func makeWalletManager(from cardId: String, walletPublicKey: Data, chainCode: Data?, blockchain: Blockchain) throws -> WalletManager {
        try makeWalletManager(from: blockchain,
                              publicKey: walletPublicKey,
                              chainCode: chainCode,
                              cardId: cardId)
    }
    
    public func makeWalletManagers(from cardId: String, walletPublicKey: Data, chainCode: Data?, blockchains: [Blockchain]) throws -> [WalletManager] {
        return try blockchains.map { try makeWalletManager(from: cardId, walletPublicKey:walletPublicKey, chainCode: chainCode, blockchain: $0) }
    }
    
    public func makeWalletManagers(for cardId: String, with walletPublicKey: Data, chainCode: Data?, and tokens: [Token]) throws -> [WalletManager] {
        let blockchainDict = Dictionary(grouping: tokens, by: { $0.blockchain })
        
        let managers: [WalletManager] = try blockchainDict.map {
            let manager = try makeWalletManager(from: cardId, walletPublicKey: walletPublicKey, chainCode: chainCode, blockchain: $0.key)
            manager.cardTokens.append(contentsOf: $0.value.filter { !manager.cardTokens.contains($0) })
            return manager
        }
        
        return managers
    }
    
    public func makeTwinWalletManager(from cardId: String, walletPublicKey: Data, pairKey: Data, isTestnet: Bool) throws -> WalletManager {
        try makeWalletManager(from: .bitcoin(testnet: isTestnet),
                              publicKey: walletPublicKey,
                              chainCode: nil,
                              cardId: cardId,
                              pairPublicKey: pairKey,
                              tokens: [])
    }
    
    func makeWalletManager(from blockchain: Blockchain,
                           publicKey: Data,
                           chainCode: Data?,
                           cardId: String,
                           pairPublicKey: Data? = nil,
                           tokens: [Token] = []) throws -> WalletManager {
        
        if blockchain.curve == .ed25519, publicKey.count > 32 { throw BlockchainSdkError.wrongKey }
        
        let wallet = try makeWallet(from: blockchain,
                                    publicKey: publicKey,
                                    chainCode: chainCode,
                                    cardId: cardId,
                                    pairPublicKey: pairPublicKey)
        
        switch blockchain {
        case .bitcoin(let testnet):
            return BitcoinWalletManager(wallet: wallet).then {
                let network: BitcoinNetwork = testnet ? .testnet : .mainnet
                let bitcoinManager = BitcoinManager(networkParams: network.networkParams,
                                                    walletPublicKey: wallet.publicKey.blockchainPublicKey,
                                                    compressedWalletPublicKey: Secp256k1Utils.compressPublicKey(wallet.publicKey.blockchainPublicKey)!,
                                                    bip: pairPublicKey == nil ? .bip84 : .bip141)
                
                $0.txBuilder = BitcoinTransactionBuilder(bitcoinManager: bitcoinManager, addresses: wallet.addresses)
                
                var providers = [AnyBitcoinNetworkProvider]()
                if !testnet {
                    providers.append(BlockchainInfoNetworkProvider()
                                        .eraseToAnyBitcoinNetworkProvider())
                }
                providers.append(BlockchairNetworkProvider(endpoint: .bitcoin(testnet: testnet),
                                                           apiKey: config.blockchairApiKey)
                                    .eraseToAnyBitcoinNetworkProvider())
                providers.append(BlockcypherNetworkProvider(endpoint: .bitcoin(testnet: testnet),
                                                            tokens: config.blockcypherTokens)
                                    .eraseToAnyBitcoinNetworkProvider())
                
                $0.networkService = BitcoinNetworkService(providers: providers)
            }
            
        case .litecoin:
            return LitecoinWalletManager(wallet: wallet).then {
                let bitcoinManager = BitcoinManager(networkParams: LitecoinNetworkParams(),
                                                    walletPublicKey: wallet.publicKey.blockchainPublicKey,
                                                    compressedWalletPublicKey: Secp256k1Utils.compressPublicKey(wallet.publicKey.blockchainPublicKey)!,
                                                    bip: .bip84)
                
                $0.txBuilder = BitcoinTransactionBuilder(bitcoinManager: bitcoinManager, addresses: wallet.addresses)
                
                var providers = [AnyBitcoinNetworkProvider]()
                providers.append(BlockchairNetworkProvider(endpoint: .litecoin,
                                                           apiKey: config.blockchairApiKey)
                                    .eraseToAnyBitcoinNetworkProvider())
                providers.append(BlockcypherNetworkProvider(endpoint: .litecoin,
                                                            tokens: config.blockcypherTokens)
                                    .eraseToAnyBitcoinNetworkProvider())
                
                $0.networkService = LitecoinNetworkService(providers: providers)
            }
            
        case .dogecoin:
            return DogecoinWalletManager(wallet: wallet).then {
                let bitcoinManager = BitcoinManager(networkParams: DogecoinNetworkParams(),
                                                    walletPublicKey: wallet.publicKey.blockchainPublicKey,
                                                    compressedWalletPublicKey: Secp256k1Utils.compressPublicKey(wallet.publicKey.blockchainPublicKey)!,
                                                    bip: .bip44)
                
                $0.txBuilder = BitcoinTransactionBuilder(bitcoinManager: bitcoinManager, addresses: wallet.addresses)
                
                var providers = [AnyBitcoinNetworkProvider]()
                providers.append(BlockchairNetworkProvider(endpoint: .dogecoin,
                                                           apiKey: config.blockchairApiKey)
                                    .eraseToAnyBitcoinNetworkProvider())
                providers.append(BlockcypherNetworkProvider(endpoint: .dogecoin,
                                                            tokens: config.blockcypherTokens)
                                    .eraseToAnyBitcoinNetworkProvider())
                
                $0.networkService = BitcoinNetworkService(providers: providers)
            }
            
        case .ducatus:
            return DucatusWalletManager(wallet: wallet).then {
                let bitcoinManager = BitcoinManager(networkParams: DucatusNetworkParams(), walletPublicKey: wallet.publicKey.blockchainPublicKey, compressedWalletPublicKey: Secp256k1Utils.compressPublicKey(wallet.publicKey.blockchainPublicKey)!, bip: .bip44)
                
                $0.txBuilder = BitcoinTransactionBuilder(bitcoinManager: bitcoinManager, addresses: wallet.addresses)
                $0.networkService = DucatusNetworkService()
            }
            
        case .stellar(let testnet):
            return StellarWalletManager(wallet: wallet, cardTokens: tokens).then {
                let url = testnet ? "https://horizon-testnet.stellar.org" : "https://horizon.stellar.org"
                let stellarSdk = StellarSDK(withHorizonUrl: url)
                $0.stellarSdk = stellarSdk
                $0.txBuilder = StellarTransactionBuilder(stellarSdk: stellarSdk, walletPublicKey: wallet.publicKey.blockchainPublicKey, isTestnet: testnet)
                $0.networkService = StellarNetworkService(stellarSdk: stellarSdk)
            }
            
        case .ethereum(let testnet):
            return EthereumWalletManager(wallet: wallet, cardTokens: tokens).then {
                let ethereumNetwork = testnet ? EthereumNetwork.testnet(projectId: config.infuraProjectId) : EthereumNetwork.mainnet(projectId: config.infuraProjectId)
                let jsonRpcProviders = [
                    EthereumJsonRpcProvider(network: ethereumNetwork),
                    EthereumJsonRpcProvider(network: .tangem)
                ]
                $0.txBuilder = EthereumTransactionBuilder(walletPublicKey: wallet.publicKey.blockchainPublicKey,
                                                          network: ethereumNetwork)
                let provider = BlockcypherNetworkProvider(endpoint: .ethereum, tokens: config.blockcypherTokens)
                let blockchair = BlockchairEthNetworkProvider(endpoint: .ethereum(testnet: testnet), apiKey: config.blockchairApiKey)
                $0.networkService = EthereumNetworkService(network: ethereumNetwork, providers: jsonRpcProviders, blockcypherProvider: provider, blockchairProvider: blockchair)
            }
            
        case .rsk:
            return EthereumWalletManager(wallet: wallet, cardTokens: tokens).then {
                let network: EthereumNetwork = .rsk
                $0.txBuilder = EthereumTransactionBuilder(walletPublicKey: wallet.publicKey.blockchainPublicKey,
                                                          network: network)
                $0.networkService = EthereumNetworkService(network: .rsk, providers: [EthereumJsonRpcProvider(network: network)], blockcypherProvider: nil, blockchairProvider: nil)
            }
            
        case .bsc(let testnet):
            return EthereumWalletManager(wallet: wallet).then {
                let network: EthereumNetwork = testnet ? .bscTestnet : .bscMainnet
                $0.txBuilder = EthereumTransactionBuilder(walletPublicKey: wallet.publicKey.blockchainPublicKey,
                                                          network: network)
                $0.networkService = EthereumNetworkService(network: network, providers: [EthereumJsonRpcProvider(network: network)], blockcypherProvider: nil, blockchairProvider: nil)
            }
            
        case .polygon(let testnet):
            return EthereumWalletManager(wallet: wallet).then {
                let network: EthereumNetwork = testnet ? .polygonTestnet : .polygon
                $0.txBuilder = EthereumTransactionBuilder(walletPublicKey: wallet.publicKey.blockchainPublicKey,
                                                          network: network)
                $0.networkService = EthereumNetworkService(network: network, providers: [EthereumJsonRpcProvider(network: network)], blockcypherProvider: nil, blockchairProvider: nil)
            }
            
        case .bitcoinCash(let testnet):
            return BitcoinCashWalletManager(wallet: wallet).then {
                let provider = BlockchairNetworkProvider(endpoint: .bitcoinCash, apiKey: config.blockchairApiKey)
                $0.txBuilder = BitcoinCashTransactionBuilder(walletPublicKey: wallet.publicKey.blockchainPublicKey, isTestnet: testnet)
                $0.networkService = BitcoinCashNetworkService(provider: provider)
            }
            
        case .binance(let testnet):
            return BinanceWalletManager(wallet: wallet, cardTokens: tokens).then {
                $0.txBuilder = BinanceTransactionBuilder(walletPublicKey: wallet.publicKey.blockchainPublicKey, isTestnet: testnet)
                $0.networkService = BinanceNetworkService(isTestNet: testnet)
            }
            
        case .cardano(let shelley):
            return CardanoWalletManager(wallet: wallet).then {
                $0.txBuilder = CardanoTransactionBuilder(walletPublicKey: wallet.publicKey.blockchainPublicKey, shelleyCard: shelley)
                let service = CardanoNetworkService(providers: [
                    AdaliteNetworkProvider(baseUrl: .main).eraseToAnyCardanoNetworkProvider(),
                    RosettaNetworkProvider(baseUrl: .tangemRosetta).eraseToAnyCardanoNetworkProvider()
                ])
                $0.networkService = service
            }
            
        case .xrp(let curve):
            return XRPWalletManager(wallet: wallet).then {
                $0.txBuilder = XRPTransactionBuilder(walletPublicKey: wallet.publicKey.blockchainPublicKey, curve: curve)
                $0.networkService = XRPNetworkService(providers: [XRPNetworkProvider(baseUrl: .xrpLedgerFoundation),
                                                                  XRPNetworkProvider(baseUrl: .ripple),
                                                                  XRPNetworkProvider(baseUrl: .rippleReserve)])
            }
        case .tezos(let curve):
            return TezosWalletManager(wallet: wallet).then {
                $0.txBuilder = TezosTransactionBuilder(walletPublicKey: wallet.publicKey.blockchainPublicKey, curve: curve)
                $0.networkService = TezosNetworkService(providers: TezosApi.makeAllProviders())
            }
        }
    }
    
    private func makeWallet(from blockchain: Blockchain,
                            publicKey: Data,
                            chainCode: Data?,
                            cardId: String,
                            pairPublicKey: Data? = nil) throws -> Wallet {
        let publicKey = try blockchain.makePublicKey(publicKey, chainCode: chainCode)
        let addresses = blockchain.makeAddresses(from: publicKey.blockchainPublicKey, with: pairPublicKey)
        return Wallet(blockchain: blockchain, addresses: addresses,
                      cardId: cardId, publicKey: publicKey)
    }
}
