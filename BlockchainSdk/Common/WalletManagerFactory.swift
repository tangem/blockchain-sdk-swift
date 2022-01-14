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
import Solana_Swift

@available(iOS 13.0, *)
public class WalletManagerFactory {
    private let config: BlockchainSdkConfig
    
    public init(config: BlockchainSdkConfig) {
        self.config = config
    }
    
    /// Base wallet manager initializer
    /// - Parameters:
    ///   - cardId: Card's cardId
    ///   - blockchain: blockhain to create. If nil, card native blockchain will be used
    ///   - seedKey: Public key  of the wallet
    ///   - derivedKey: Derived ExtendedPublicKey by the card
    ///   - derivationPath: DerivationPath for derivedKey
    /// - Returns: WalletManager?
    public func makeWalletManager(cardId: String,
                                  blockchain: Blockchain,
                                  seedKey: Data,
                                  derivedKey: ExtendedPublicKey) throws -> WalletManager {
        return try makeWalletManager(from: blockchain,
                                     publicKey: .init(seedKey: seedKey,
                                                      derivedKey: derivedKey.publicKey,
                                                      derivationPath: blockchain.derivationPath),
                                     cardId: cardId)
    }
    
    /// Legacy wallet manager initializer
    /// - Parameters:
    ///   - cardId: Card's cardId
    ///   - blockchain: blockhain to create. If nil, card native blockchain will be used
    ///   - walletPublicKey: Wallet's publicKey
    /// - Returns: WalletManager
    public func makeWalletManager(cardId: String, blockchain: Blockchain, walletPublicKey: Data) throws -> WalletManager {
        try makeWalletManager(from: blockchain,
                              publicKey: .init(seedKey: walletPublicKey, derivedKey: nil, derivationPath: nil),
                              cardId: cardId)
    }
    
    /// Wallet manager initializer for twin cards
    /// - Parameters:
    ///   - cardId: Card's cardId
    ///   - blockchain: blockhain to create. If nil, card native blockchain will be used
    ///   - walletPublicKey: Wallet's publicKey
    public func makeTwinWalletManager(from cardId: String, walletPublicKey: Data, pairKey: Data, isTestnet: Bool) throws -> WalletManager {
        try makeWalletManager(from: .bitcoin(testnet: isTestnet),
                              publicKey: .init(seedKey: walletPublicKey, derivedKey: nil, derivationPath: nil),
                              cardId: cardId,
                              pairPublicKey: pairKey,
                              tokens: [])
    }
    
    func makeWalletManager(from blockchain: Blockchain,
                           publicKey: Wallet.PublicKey,
                           cardId: String,
                           pairPublicKey: Data? = nil,
                           tokens: [Token] = []) throws -> WalletManager {
        
        if blockchain.curve == .ed25519, publicKey.seedKey.count > 32 || publicKey.blockchainKey.count > 32  {
            throw BlockchainSdkError.wrongKey
        }
        
        let addresses = try blockchain.makeAddresses(from: publicKey.blockchainKey, with: pairPublicKey)
        let wallet = Wallet(blockchain: blockchain,
                            addresses: addresses,
                            cardId: cardId,
                            publicKey: publicKey)
        
        switch blockchain {
        case .bitcoin(let testnet):
            return try BitcoinWalletManager(wallet: wallet).then {
                let network: BitcoinNetwork = testnet ? .testnet : .mainnet
                let bitcoinManager = BitcoinManager(networkParams: network.networkParams,
                                                    walletPublicKey: wallet.publicKey.blockchainKey,
                                                    compressedWalletPublicKey: try Secp256k1Key(with: wallet.publicKey.blockchainKey).compress(),
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
            return try LitecoinWalletManager(wallet: wallet).then {
                let bitcoinManager = BitcoinManager(networkParams: LitecoinNetworkParams(),
                                                    walletPublicKey: wallet.publicKey.blockchainKey,
                                                    compressedWalletPublicKey: try Secp256k1Key(with: wallet.publicKey.blockchainKey).compress(),
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
            return try DogecoinWalletManager(wallet: wallet).then {
                let bitcoinManager = BitcoinManager(networkParams: DogecoinNetworkParams(),
                                                    walletPublicKey: wallet.publicKey.blockchainKey,
                                                    compressedWalletPublicKey: try Secp256k1Key(with: wallet.publicKey.blockchainKey).compress(),
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
            return try DucatusWalletManager(wallet: wallet).then {
                let bitcoinManager = BitcoinManager(networkParams: DucatusNetworkParams(), walletPublicKey: wallet.publicKey.blockchainKey, compressedWalletPublicKey: try Secp256k1Key(with: wallet.publicKey.blockchainKey).compress(), bip: .bip44)
                
                $0.txBuilder = BitcoinTransactionBuilder(bitcoinManager: bitcoinManager, addresses: wallet.addresses)
                $0.networkService = DucatusNetworkService()
            }
            
        case .stellar(let testnet):
            return StellarWalletManager(wallet: wallet, cardTokens: tokens).then {
                let url = testnet ? "https://horizon-testnet.stellar.org" : "https://horizon.stellar.org"
                let stellarSdk = StellarSDK(withHorizonUrl: url)
                $0.stellarSdk = stellarSdk
                $0.txBuilder = StellarTransactionBuilder(stellarSdk: stellarSdk, walletPublicKey: wallet.publicKey.blockchainKey, isTestnet: testnet)
                $0.networkService = StellarNetworkService(stellarSdk: stellarSdk)
            }
            
        case .ethereum(let testnet):
            return try EthereumWalletManager(wallet: wallet, cardTokens: tokens).then {
                let ethereumNetwork = testnet ? EthereumNetwork.testnet(projectId: config.infuraProjectId) : EthereumNetwork.mainnet(projectId: config.infuraProjectId)
                let jsonRpcProviders = [
                    EthereumJsonRpcProvider(network: ethereumNetwork),
                    EthereumJsonRpcProvider(network: .tangem)
                ]
                $0.txBuilder = try EthereumTransactionBuilder(walletPublicKey: wallet.publicKey.blockchainKey,
                                                              network: ethereumNetwork)
                let provider = BlockcypherNetworkProvider(endpoint: .ethereum, tokens: config.blockcypherTokens)
                let blockchair = BlockchairEthNetworkProvider(endpoint: .ethereum(testnet: testnet), apiKey: config.blockchairApiKey)
                $0.networkService = EthereumNetworkService(network: ethereumNetwork, providers: jsonRpcProviders, blockcypherProvider: provider, blockchairProvider: blockchair)
            }
            
        case .rsk:
            return try EthereumWalletManager(wallet: wallet, cardTokens: tokens).then {
                let network: EthereumNetwork = .rsk
                $0.txBuilder = try EthereumTransactionBuilder(walletPublicKey: wallet.publicKey.blockchainKey,
                                                              network: network)
                $0.networkService = EthereumNetworkService(network: .rsk, providers: [EthereumJsonRpcProvider(network: network)], blockcypherProvider: nil, blockchairProvider: nil)
            }
            
        case .bsc(let testnet):
            return try EthereumWalletManager(wallet: wallet).then {
                let network: EthereumNetwork = testnet ? .bscTestnet : .bscMainnet
                $0.txBuilder = try EthereumTransactionBuilder(walletPublicKey: wallet.publicKey.blockchainKey,
                                                              network: network)
                $0.networkService = EthereumNetworkService(network: network, providers: [EthereumJsonRpcProvider(network: network)], blockcypherProvider: nil, blockchairProvider: nil)
            }
            
        case .polygon(let testnet):
            return try EthereumWalletManager(wallet: wallet).then {
                let network: EthereumNetwork = testnet ? .polygonTestnet : .polygon
                $0.txBuilder = try EthereumTransactionBuilder(walletPublicKey: wallet.publicKey.blockchainKey,
                                                              network: network)
                $0.networkService = EthereumNetworkService(network: network, providers: [EthereumJsonRpcProvider(network: network)], blockcypherProvider: nil, blockchairProvider: nil)
            }
            
        case .bitcoinCash(let testnet):
            return try BitcoinCashWalletManager(wallet: wallet).then {
                let provider = BlockchairNetworkProvider(endpoint: .bitcoinCash, apiKey: config.blockchairApiKey)
                $0.txBuilder = try BitcoinCashTransactionBuilder(walletPublicKey: wallet.publicKey.blockchainKey, isTestnet: testnet)
                $0.networkService = BitcoinCashNetworkService(provider: provider)
            }
            
        case .binance(let testnet):
            return try BinanceWalletManager(wallet: wallet, cardTokens: tokens).then {
                $0.txBuilder = try BinanceTransactionBuilder(walletPublicKey: wallet.publicKey.blockchainKey, isTestnet: testnet)
                $0.networkService = BinanceNetworkService(isTestNet: testnet)
            }
            
        case .cardano(let shelley):
            return CardanoWalletManager(wallet: wallet).then {
                $0.txBuilder = CardanoTransactionBuilder(walletPublicKey: wallet.publicKey.blockchainKey, shelleyCard: shelley)
                let service = CardanoNetworkService(providers: [
                    AdaliteNetworkProvider(baseUrl: .main).eraseToAnyCardanoNetworkProvider(),
                    RosettaNetworkProvider(baseUrl: .tangemRosetta).eraseToAnyCardanoNetworkProvider()
                ])
                $0.networkService = service
            }
            
        case .xrp(let curve):
            return try XRPWalletManager(wallet: wallet).then {
                $0.txBuilder = try XRPTransactionBuilder(walletPublicKey: wallet.publicKey.blockchainKey, curve: curve)
                $0.networkService = XRPNetworkService(providers: [XRPNetworkProvider(baseUrl: .xrpLedgerFoundation),
                                                                  XRPNetworkProvider(baseUrl: .ripple),
                                                                  XRPNetworkProvider(baseUrl: .rippleReserve)])
            }
        case .tezos(let curve):
            return try TezosWalletManager(wallet: wallet).then {
                $0.txBuilder = try TezosTransactionBuilder(walletPublicKey: wallet.publicKey.blockchainKey, curve: curve)
                $0.networkService = TezosNetworkService(providers: TezosApi.makeAllProviders())
            }
        case .solana(let testnet):
            return SolanaWalletManager(wallet: wallet, cardTokens: tokens).then {
                let endpoint: RPCEndpoint = testnet ? .testnetSolana : .mainnetBetaSolana
                let networkRouter = NetworkingRouter(endpoint: endpoint)
                let accountStorage = SolanaDummyAccountStorage()
                
                $0.solanaSdk = Solana(router: networkRouter, accountStorage: accountStorage)
            }
        }
    }
}
