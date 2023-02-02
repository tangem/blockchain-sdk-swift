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
                                                      derivedKey: derivedKey,
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
        
        let networkProviderConfiguration = config.networkProviderConfiguration(for: blockchain)
        
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
                
                providers.append(BlockBookUtxoProvider(blockchain: blockchain,
                                                       blockBookConfig: NowNodesBlockBookConfig(apiKey: config.nowNodesApiKey),
                                                       networkConfiguration: networkProviderConfiguration)
                    .eraseToAnyBitcoinNetworkProvider())
                
                if !testnet {
                    providers.append(BlockBookUtxoProvider(blockchain: blockchain,
                                                           blockBookConfig: GetBlockBlockBookConfig(apiKey: config.getBlockApiKey),
                                                           networkConfiguration: networkProviderConfiguration)
                        .eraseToAnyBitcoinNetworkProvider())
                    
                    providers.append(BlockchainInfoNetworkProvider(configuration: networkProviderConfiguration)
                        .eraseToAnyBitcoinNetworkProvider())
                }
                
                providers.append(contentsOf: makeBlockchairNetworkProviders(for: .bitcoin(testnet: testnet),
                                                                            configuration: networkProviderConfiguration,
                                                                            apiKeys: config.blockchairApiKeys))
                
                providers.append(BlockcypherNetworkProvider(endpoint: .bitcoin(testnet: testnet),
                                                            tokens: config.blockcypherTokens,
                                                            configuration: networkProviderConfiguration)
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
                
                providers.append(BlockBookUtxoProvider(blockchain: blockchain,
                                                       blockBookConfig: NowNodesBlockBookConfig(apiKey: config.nowNodesApiKey),
                                                       networkConfiguration: networkProviderConfiguration)
                    .eraseToAnyBitcoinNetworkProvider())
                
                providers.append(BlockBookUtxoProvider(blockchain: blockchain,
                                                       blockBookConfig: GetBlockBlockBookConfig(apiKey: config.getBlockApiKey),
                                                       networkConfiguration: networkProviderConfiguration)
                    .eraseToAnyBitcoinNetworkProvider())
                
                providers.append(contentsOf: makeBlockchairNetworkProviders(for: .litecoin,
                                                                            configuration: networkProviderConfiguration,
                                                                            apiKeys: config.blockchairApiKeys))
                
                providers.append(BlockcypherNetworkProvider(endpoint: .litecoin,
                                                            tokens: config.blockcypherTokens,
                                                            configuration: networkProviderConfiguration)
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
                
                providers.append(BlockBookUtxoProvider(blockchain: blockchain,
                                                       blockBookConfig: NowNodesBlockBookConfig(apiKey: config.nowNodesApiKey),
                                                       networkConfiguration: networkProviderConfiguration)
                    .eraseToAnyBitcoinNetworkProvider())
                
                providers.append(BlockBookUtxoProvider(blockchain: blockchain,
                                                       blockBookConfig: GetBlockBlockBookConfig(apiKey: config.getBlockApiKey),
                                                       networkConfiguration: networkProviderConfiguration)
                    .eraseToAnyBitcoinNetworkProvider())
                
                providers.append(contentsOf: makeBlockchairNetworkProviders(for: .dogecoin,
                                                                            configuration: networkProviderConfiguration,
                                                                            apiKeys: config.blockchairApiKeys))
                
                providers.append(BlockcypherNetworkProvider(
                    endpoint: .dogecoin,
                    tokens: config.blockcypherTokens,
                    configuration: networkProviderConfiguration
                )
                    .eraseToAnyBitcoinNetworkProvider())
                
                $0.networkService = BitcoinNetworkService(providers: providers)
            }
            
        case .ducatus:
            return try DucatusWalletManager(wallet: wallet).then {
                let bitcoinManager = BitcoinManager(networkParams: DucatusNetworkParams(), walletPublicKey: wallet.publicKey.blockchainKey, compressedWalletPublicKey: try Secp256k1Key(with: wallet.publicKey.blockchainKey).compress(), bip: .bip44)
                
                $0.txBuilder = BitcoinTransactionBuilder(bitcoinManager: bitcoinManager, addresses: wallet.addresses)
                $0.networkService = DucatusNetworkService(configuration: networkProviderConfiguration)
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
            let endpoints = blockchain.getJsonRpcEndpoints(
                keys: EthereumApiKeys(
                    infuraProjectId: config.infuraProjectId,
                    nowNodesApiKey: config.nowNodesApiKey,
                    getBlockApiKey: config.getBlockApiKey,
                    quickNodeBscCredentials: config.quickNodeBscCredentials
                )
            )!
            
            if case .optimism = blockchain {
                manager = OptimismWalletManager(wallet: wallet, rpcURL: endpoints[0].url)
            } else {
                manager = EthereumWalletManager(wallet: wallet)
            }
            
            let blockcypherProvider: BlockcypherNetworkProvider?
            
            if case .ethereum = blockchain {
                blockcypherProvider = BlockcypherNetworkProvider(
                    endpoint: .ethereum,
                    tokens: config.blockcypherTokens,
                    configuration: networkProviderConfiguration
                )
            } else {
                blockcypherProvider = nil
            }
            
            return try manager.then {
                let chainId = blockchain.chainId!
                
                let jsonRpcProviders = endpoints.map {
                    var additionalHeaders: [String: String] = [:]
                    if let apiKeyHeaderName = $0.apiKeyHeaderName, let apiKeyHeaderValue = $0.apiKeyHeaderValue {
                        additionalHeaders[apiKeyHeaderName] = apiKeyHeaderValue
                    }
                    
                    return EthereumJsonRpcProvider(
                        url: $0.url,
                        additionalHeaders: additionalHeaders,
                        configuration: networkProviderConfiguration
                    )
                }
                
                $0.txBuilder = try EthereumTransactionBuilder(walletPublicKey: wallet.publicKey.blockchainKey, chainId: chainId)
                $0.networkService = EthereumNetworkService(decimals: blockchain.decimalCount,
                                                           providers: jsonRpcProviders,
                                                           blockcypherProvider: blockcypherProvider,
                                                           blockchairProvider: nil) //TODO: TBD Do we need the TokenFinder feature?
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
                
                if !testnet {
                    providers.append(BlockBookUtxoProvider(blockchain: blockchain,
                                                           blockBookConfig: NowNodesBlockBookConfig(apiKey: config.nowNodesApiKey),
                                                           networkConfiguration: networkProviderConfiguration)
                        .eraseToAnyBitcoinNetworkProvider())
                    
                    providers.append(BlockBookUtxoProvider(blockchain: blockchain,
                                                           blockBookConfig: GetBlockBlockBookConfig(apiKey: config.getBlockApiKey),
                                                           networkConfiguration: networkProviderConfiguration)
                        .eraseToAnyBitcoinNetworkProvider())
                }
                
                providers.append(contentsOf: makeBlockchairNetworkProviders(for: .bitcoinCash,
                                                                            configuration: networkProviderConfiguration,
                                                                            apiKeys: config.blockchairApiKeys))
                
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
                        configuration: networkProviderConfiguration
                    ).eraseToAnyCardanoNetworkProvider(),
                    RosettaNetworkProvider(
                        baseUrl: .tangemRosetta,
                        configuration: networkProviderConfiguration
                    ).eraseToAnyCardanoNetworkProvider()
                ])
                $0.networkService = service
            }
            
        case .xrp(let curve):
            return try XRPWalletManager(wallet: wallet).then {
                $0.txBuilder = try XRPTransactionBuilder(walletPublicKey: wallet.publicKey.blockchainKey, curve: curve)
                $0.networkService = XRPNetworkService(providers: [
                    XRPNetworkProvider(baseUrl: .xrpLedgerFoundation, configuration: networkProviderConfiguration),
                    XRPNetworkProvider(baseUrl: .ripple, configuration: networkProviderConfiguration),
                    XRPNetworkProvider(baseUrl: .rippleReserve, configuration: networkProviderConfiguration)
                ])
            }
            
        case .tezos(let curve):
            return try TezosWalletManager(wallet: wallet).then {
                $0.txBuilder = try TezosTransactionBuilder(walletPublicKey: wallet.publicKey.blockchainKey, curve: curve)
                $0.networkService = TezosNetworkService(
                    providers: TezosApi.makeAllProviders(configuration: networkProviderConfiguration)
                )
            }
            
        case .solana(let testnet):
            return SolanaWalletManager(wallet: wallet).then {
                let endpoints: [Solana_Swift.RPCEndpoint]
                if testnet {
                    endpoints = [
                        .devnetSolana,
                        .devnetGenesysGo,
                    ]
                } else {
                    endpoints = [
                        .nowNodes(apiKey: config.nowNodesApiKey),
                        .getBlock(apiKey: config.getBlockApiKey),
                        .quiknode(apiKey: config.quickNodeSolanaCredentials.apiKey, subdomain: config.quickNodeSolanaCredentials.subdomain),
                        .ankr,
                        .mainnetBetaSolana,
                    ]
                }
                
                let networkRouter = NetworkingRouter(endpoints: endpoints)
                let accountStorage = SolanaDummyAccountStorage()
                
                $0.solanaSdk = Solana(router: networkRouter, accountStorage: accountStorage)
                $0.networkService = SolanaNetworkService(solanaSdk: $0.solanaSdk, blockchain: blockchain, hostProvider: networkRouter)
            }
        case .polkadot(let testnet):
            return makePolkadotWalletManager(network: testnet ? .westend : .polkadot, wallet: wallet, networkProviderConfiguration: networkProviderConfiguration)
        case .kusama:
            return makePolkadotWalletManager(network: .kusama, wallet: wallet, networkProviderConfiguration: networkProviderConfiguration)
        case .tron(let testnet):
            return TronWalletManager(wallet: wallet).then {
                let network: TronNetwork = testnet ? .nile : .mainnet
                let providers = [
                    TronJsonRpcProvider(
                        network: network,
                        tronGridApiKey: nil,
                        configuration: networkProviderConfiguration
                    ),
                    TronJsonRpcProvider(
                        network: network,
                        tronGridApiKey: config.tronGridApiKey,
                        configuration: networkProviderConfiguration
                    ),
                ]
                $0.networkService = TronNetworkService(isTestnet: testnet, providers: providers)
                $0.txBuilder = TronTransactionBuilder(blockchain: blockchain)
            }
        case .ton(testnet: let testnet):
            let assemblyInput = BlockchainAssemblyFactoryInput(
                blockchain: blockchain,
                blockchainConfig: config,
                publicKey: publicKey,
                pairPublicKey: pairPublicKey,
                wallet: wallet,
                networkConfig: networkProviderConfiguration
            )
            
            return try TONBlockchainAssemblyFactory().assembly(with: assemblyInput, isTestnet: testnet)
        case .dash(let testnet):
            return try makeDashWalletManager(testnet: testnet, wallet: wallet, networkProviderConfiguration: networkProviderConfiguration)
        }
    }
    
    private func makePolkadotWalletManager(network: PolkadotNetwork,
                                           wallet: Wallet,
                                           networkProviderConfiguration: NetworkProviderConfiguration) -> WalletManager {
        PolkadotWalletManager(network: network, wallet: wallet).then {
            let providers = network.urls.map { url in
                PolkadotJsonRpcProvider(url: url, configuration: networkProviderConfiguration)
            }
            $0.networkService = PolkadotNetworkService(providers: providers, network: network)
            $0.txBuilder = PolkadotTransactionBuilder(walletPublicKey: wallet.publicKey.blockchainKey, network: network)
        }
    }
    
    private func makeDashWalletManager(testnet: Bool,
                                       wallet: Wallet,
                                       networkProviderConfiguration: NetworkProviderConfiguration) throws -> WalletManager {
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
            
            var providers: [AnyBitcoinNetworkProvider] = []
            
            providers.append(BlockBookUtxoProvider(blockchain: .dash(testnet: testnet),
                                                   blockBookConfig: NowNodesBlockBookConfig(apiKey: config.nowNodesApiKey),
                                                   networkConfiguration: networkProviderConfiguration)
                .eraseToAnyBitcoinNetworkProvider())
            
            providers.append(BlockBookUtxoProvider(blockchain: .dash(testnet: testnet),
                                                   blockBookConfig: GetBlockBlockBookConfig(apiKey: config.getBlockApiKey),
                                                   networkConfiguration: networkProviderConfiguration)
                .eraseToAnyBitcoinNetworkProvider())
            
            providers.append(contentsOf: makeBlockchairNetworkProviders(for: .dash,
                                                                        configuration: networkProviderConfiguration,
                                                                        apiKeys: config.blockchairApiKeys))
            
            providers.append(BlockcypherNetworkProvider(endpoint: .dash,
                                                        tokens: config.blockcypherTokens,
                                                        configuration: networkProviderConfiguration)
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

extension WalletManagerFactory {
    public enum DerivationParams {
        case `default`(DerivationStyle)
        case custom(DerivationPath)
    }
}
