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
    ///   - blockchain: blockhain to create. If nil, card native blockchain will be used
    ///   - seedKey: Public key  of the wallet
    ///   - derivedKey: Derived ExtendedPublicKey by the card
    ///   - derivation: DerivationParams
    /// - Returns: WalletManager?
    public func makeWalletManager(blockchain: Blockchain,
                                  seedKey: Data,
                                  derivedKey: ExtendedPublicKey,
                                  derivation: DerivationParams) throws -> WalletManager {
        
        var derivationPath: DerivationPath? = nil
        
        switch derivation {
        case .default(let derivationStyle):
            derivationPath = blockchain.derivationPath(for: derivationStyle)
        case .custom(let path):
            derivationPath = path
        }
        
        return try makeWalletManager(from: blockchain,
                                     publicKey: .init(seedKey: seedKey,
                                                      derivedKey: derivedKey.publicKey,
                                                      derivationPath: derivationPath))
    }
    
    /// Legacy wallet manager initializer
    /// - Parameters:
    ///   - blockchain: blockhain to create. If nil, card native blockchain will be used
    ///   - walletPublicKey: Wallet's publicKey
    /// - Returns: WalletManager
    public func makeWalletManager(blockchain: Blockchain, walletPublicKey: Data) throws -> WalletManager {
        try makeWalletManager(from: blockchain,
                              publicKey: .init(seedKey: walletPublicKey, derivedKey: nil, derivationPath: nil))
    }
    
    /// Wallet manager initializer for twin cards
    /// - Parameters:
    ///   - blockchain: blockhain to create. If nil, card native blockchain will be used
    ///   - walletPublicKey: Wallet's publicKey
    public func makeTwinWalletManager(walletPublicKey: Data, pairKey: Data, isTestnet: Bool) throws -> WalletManager {
        try makeWalletManager(from: .bitcoin(testnet: isTestnet),
                              publicKey: .init(seedKey: walletPublicKey, derivedKey: nil, derivationPath: nil),
                              pairPublicKey: pairKey)
    }
    
    func makeWalletManager(from blockchain: Blockchain,
                           publicKey: Wallet.PublicKey,
                           pairPublicKey: Data? = nil) throws -> WalletManager {
        let addresses = try blockchain.makeAddresses(from: publicKey.blockchainKey, with: pairPublicKey)
        let wallet = Wallet(blockchain: blockchain,
                            addresses: addresses,
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
                    providers.append(BlockchainInfoNetworkProvider(configuration: config.networkProviderConfiguration)
                                        .eraseToAnyBitcoinNetworkProvider())
                }
                providers.append(BlockchairNetworkProvider(endpoint: .bitcoin(testnet: testnet),
                                                           apiKey: config.blockchairApiKey,
                                                           configuration: config.networkProviderConfiguration)
                                    .eraseToAnyBitcoinNetworkProvider())
                providers.append(BlockcypherNetworkProvider(endpoint: .bitcoin(testnet: testnet),
                                                            tokens: config.blockcypherTokens,
                                                            configuration: config.networkProviderConfiguration)
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
                                                           apiKey: config.blockchairApiKey,
                                                           configuration: config.networkProviderConfiguration)
                                    .eraseToAnyBitcoinNetworkProvider())
                providers.append(BlockcypherNetworkProvider(endpoint: .litecoin,
                                                            tokens: config.blockcypherTokens,
                                                            configuration: config.networkProviderConfiguration)
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
                
                let providers: [AnyBitcoinNetworkProvider] = [
                    BlockchairNetworkProvider(
                        endpoint: .dogecoin,
                        apiKey: config.blockchairApiKey,
                        configuration: config.networkProviderConfiguration
                    )
                    .eraseToAnyBitcoinNetworkProvider(),
                    BlockcypherNetworkProvider(
                        endpoint: .dogecoin,
                        tokens: config.blockcypherTokens,
                        configuration: config.networkProviderConfiguration
                    )
                    .eraseToAnyBitcoinNetworkProvider()
                ]
                
                $0.networkService = BitcoinNetworkService(providers: providers)
            }
            
        case .ducatus:
            return try DucatusWalletManager(wallet: wallet).then {
                let bitcoinManager = BitcoinManager(networkParams: DucatusNetworkParams(), walletPublicKey: wallet.publicKey.blockchainKey, compressedWalletPublicKey: try Secp256k1Key(with: wallet.publicKey.blockchainKey).compress(), bip: .bip44)
                
                $0.txBuilder = BitcoinTransactionBuilder(bitcoinManager: bitcoinManager, addresses: wallet.addresses)
                $0.networkService = DucatusNetworkService(configuration: config.networkProviderConfiguration)
            }
            
        case .stellar(let testnet):
            return StellarWalletManager(wallet: wallet).then {
                let url = testnet ? "https://horizon-testnet.stellar.org" : "https://horizon.stellar.org"
                let stellarSdk = StellarSDK(withHorizonUrl: url)
                $0.stellarSdk = stellarSdk
                $0.txBuilder = StellarTransactionBuilder(stellarSdk: stellarSdk, walletPublicKey: wallet.publicKey.blockchainKey, isTestnet: testnet)
                $0.networkService = StellarNetworkService(isTestnet: testnet, stellarSdk: stellarSdk)
            }
        case .ethereum, .ethereumClassic, .rsk, .bsc, .polygon, .avalanche, .fantom, .arbitrum, .gnosis, .ethereumPoW, .optimism, .ethereumFair, .saltPay:
            let manager: EthereumWalletManager
            let rpcUrls = blockchain.getJsonRpcURLs(infuraProjectId: config.infuraProjectId)!
            
            if case .optimism = blockchain {
                manager = OptimismWalletManager(wallet: wallet)
                if let manager = manager as? OptimismWalletManager {
                    manager.rpcURL = rpcUrls[0]
                }
            } else {
                manager = EthereumWalletManager(wallet: wallet)
            }
            
            let blockcypher: BlockcypherNetworkProvider?
            let blockchair: BlockchairNetworkProvider?
            
            if case .ethereum = blockchain {
                blockcypher = BlockcypherNetworkProvider(
                    endpoint: .ethereum,
                    tokens: config.blockcypherTokens,
                    configuration: config.networkProviderConfiguration
                )
                
                blockchair = BlockchairNetworkProvider(
                    endpoint: .ethereum(testnet: blockchain.isTestnet),
                    apiKey: config.blockchairApiKey,
                    configuration: config.networkProviderConfiguration
                )
            } else {
                blockcypher = nil
                blockchair = nil
            }
            
            return try manager.then {
                let chainId = blockchain.chainId!
                let jsonRpcProviders = rpcUrls.map {
                    EthereumJsonRpcProvider(url: $0, configuration: config.networkProviderConfiguration)
                }
                
                if case .ethereum = blockchain {
                    
                }
                
                $0.txBuilder = try EthereumTransactionBuilder(walletPublicKey: wallet.publicKey.blockchainKey, chainId: chainId)
                $0.networkService = EthereumNetworkService(decimals: blockchain.decimalCount,
                                                           providers: jsonRpcProviders,
                                                           blockcypherProvider: blockcypher,
                                                           blockchairProvider: blockchair)
            }
        case .bitcoinCash(let testnet):
            return try BitcoinCashWalletManager(wallet: wallet).then {
                let compressed = try Secp256k1Key(with: wallet.publicKey.blockchainKey).compress()
                let bitcoinManager = BitcoinManager(networkParams: testnet ? BitcoinCashTestNetworkParams() : BitcoinCashNetworkParams(),
                                                    walletPublicKey: compressed,
                                                    compressedWalletPublicKey: compressed,
                                                    bip: .bip44)
                
                $0.txBuilder = BitcoinTransactionBuilder(bitcoinManager: bitcoinManager, addresses: wallet.addresses)
                
                //TODO: Add testnet support. Maybe https://developers.cryptoapis.io/technical-documentation/general-information/what-we-support
                var providers = [AnyBitcoinNetworkProvider]()
                providers.append(BlockchairNetworkProvider(
                    endpoint: .bitcoinCash,
                    apiKey: config.blockchairApiKey,
                    configuration: config.networkProviderConfiguration
                ).eraseToAnyBitcoinNetworkProvider())
                $0.networkService = BitcoinCashNetworkService(providers: providers)
            }

        case .binance(let testnet):
            return try BinanceWalletManager(wallet: wallet).then {
                $0.txBuilder = try BinanceTransactionBuilder(walletPublicKey: wallet.publicKey.blockchainKey, isTestnet: testnet)
                $0.networkService = BinanceNetworkService(isTestNet: testnet)
            }
            
        case .cardano(let shelley):
            return CardanoWalletManager(wallet: wallet).then {
                $0.txBuilder = CardanoTransactionBuilder(walletPublicKey: wallet.publicKey.blockchainKey, shelleyCard: shelley)
                let service = CardanoNetworkService(providers: [
                    AdaliteNetworkProvider(
                        baseUrl: .main,
                        configuration: config.networkProviderConfiguration
                    ).eraseToAnyCardanoNetworkProvider(),
                    RosettaNetworkProvider(
                        baseUrl: .tangemRosetta,
                        configuration: config.networkProviderConfiguration
                    ).eraseToAnyCardanoNetworkProvider()
                ])
                $0.networkService = service
            }
            
        case .xrp(let curve):
            return try XRPWalletManager(wallet: wallet).then {
                $0.txBuilder = try XRPTransactionBuilder(walletPublicKey: wallet.publicKey.blockchainKey, curve: curve)
                $0.networkService = XRPNetworkService(providers: [
                    XRPNetworkProvider(baseUrl: .xrpLedgerFoundation, configuration: config.networkProviderConfiguration),
                    XRPNetworkProvider(baseUrl: .ripple, configuration: config.networkProviderConfiguration),
                    XRPNetworkProvider(baseUrl: .rippleReserve, configuration: config.networkProviderConfiguration)
                ])
            }
            
        case .tezos(let curve):
            return try TezosWalletManager(wallet: wallet).then {
                $0.txBuilder = try TezosTransactionBuilder(walletPublicKey: wallet.publicKey.blockchainKey, curve: curve)
                $0.networkService = TezosNetworkService(
                    providers: TezosApi.makeAllProviders(configuration: config.networkProviderConfiguration)
                )
            }
            
        case .solana(let testnet):
            return SolanaWalletManager(wallet: wallet).then {
                let endpoint: RPCEndpoint = testnet ? .devnetSolana : .mainnetBetaSolana
                let networkRouter = NetworkingRouter(endpoint: endpoint)
                let accountStorage = SolanaDummyAccountStorage()
                
                $0.solanaSdk = Solana(router: networkRouter, accountStorage: accountStorage)
                $0.networkService = SolanaNetworkService(host: endpoint.url.hostOrUnknown, solanaSdk: $0.solanaSdk, blockchain: blockchain)
            }
        case .polkadot(let testnet):
            return makePolkadotWalletManager(network: testnet ? .westend : .polkadot, wallet: wallet)
        case .kusama:
            return makePolkadotWalletManager(network: .kusama, wallet: wallet)
        case .tron(let testnet):
            return TronWalletManager(wallet: wallet).then {
                let network: TronNetwork = testnet ? .nile : .mainnet
                let providers = [
                    TronJsonRpcProvider(
                        network: network,
                        tronGridApiKey: nil,
                        configuration: config.networkProviderConfiguration
                    ),
                    TronJsonRpcProvider(
                        network: network,
                        tronGridApiKey: config.tronGridApiKey,
                        configuration: config.networkProviderConfiguration
                    ),
                ]
                $0.networkService = TronNetworkService(isTestnet: testnet, providers: providers)
                $0.txBuilder = TronTransactionBuilder(blockchain: blockchain)
            }
        case .dash(let testnet):
            return try makeDashWalletManager(testnet: testnet, wallet: wallet)
        }
    }
    
    private func makePolkadotWalletManager(network: PolkadotNetwork, wallet: Wallet) -> WalletManager {
        PolkadotWalletManager(network: network, wallet: wallet).then {
            $0.networkService = PolkadotNetworkService(
                rpcProvider: PolkadotJsonRpcProvider(network: network, configuration: config.networkProviderConfiguration)
            )
            $0.txBuilder = PolkadotTransactionBuilder(walletPublicKey: wallet.publicKey.blockchainKey, network: network)
        }
    }
    
    private func makeDashWalletManager(testnet: Bool, wallet: Wallet) throws -> WalletManager {
        try DashWalletManager(wallet: wallet).then {
            let compressed = try Secp256k1Key(with: wallet.publicKey.blockchainKey).compress()

            let bitcoinManager = BitcoinManager(
                networkParams: testnet ? DashTestNetworkParams() : DashMainNetworkParams(),
                walletPublicKey: wallet.publicKey.blockchainKey,
                compressedWalletPublicKey: compressed,
                bip: .bip44
            )
            
            // TODO: Add CryptoAPIs for testnet
            
            $0.txBuilder = BitcoinTransactionBuilder(bitcoinManager: bitcoinManager, addresses: wallet.addresses)
            
            let blockchairProvider = BlockchairNetworkProvider(
                endpoint: .dash,
                apiKey: config.blockchairApiKey,
                configuration: config.networkProviderConfiguration
            )
            let blockcypherProvider = BlockcypherNetworkProvider(
                endpoint: .dash,
                tokens: config.blockcypherTokens,
                configuration: config.networkProviderConfiguration
            )
            
            $0.networkService = BitcoinNetworkService(
                providers: [blockchairProvider.eraseToAnyBitcoinNetworkProvider(),
                            blockcypherProvider.eraseToAnyBitcoinNetworkProvider()]
            )
        }
    }
}

extension WalletManagerFactory {
    public enum DerivationParams {
        case `default`(DerivationStyle)
        case custom(DerivationPath)
    }
}
