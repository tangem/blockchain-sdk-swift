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
import BitcoinCoreSPV

public class WalletManagerFactory {
    private let config: BlockchainSdkConfig
    public init(config: BlockchainSdkConfig) {
        self.config = config
    }
        
    public func makeWalletManager(from card: Card, tokens: [Token]? = nil, pairKey: Data? = nil) -> WalletManager? {
        guard let blockchain = getBlockchain(from: card),
            let walletPublicKey = card.walletPublicKey,
            let cardId = card.cardId else {
                return nil
        }
        
        let tokens = tokens ?? getToken(from: card).map { [$0] } ?? []
		return makeWalletManager(from: blockchain, walletPublicKey: walletPublicKey, cardId: cardId, walletPairPublicKey: pairKey, tokens: tokens)
	}
	
    public func makeWalletManager(from blockchain: Blockchain, walletPublicKey: Data, cardId: String, walletPairPublicKey: Data? = nil, tokens: [Token] = []) -> WalletManager {
		let addresses = blockchain.makeAddresses(from: walletPublicKey, with: walletPairPublicKey)
		let wallet = Wallet(blockchain: blockchain,
                            addresses: addresses)
		
        switch blockchain {
        case .bitcoin(let testnet):
            return BitcoinWalletManager(cardId: cardId, wallet: wallet).then {
                let network: BitcoinNetwork = testnet ? .testnet : .mainnet
                
//                let compressedPubKey = Secp256k1Utils.convertKeyToCompressed(walletPublicKey)!
//                let bip: Bip = walletPairPublicKey == nil ? .bip84 : .bip141
                
                // This is not compressed pub key. This is script hex for multisig address: bc1q0la5l9hx070af345nc2f5ggukrjgfusan4vglqnrenxuarhcp0pqzrr4p4
                // This address has a lot of transactions in december so if you need tx history, you should use this with BIP 141
                let compressedPubKey = Data(hex: "7ffb4f96e67f9fd4c6b49e149a211cb0e484f21d9d588f8263cccdce8ef80bc2")
                let bip = Bip.bip141
                
//
                
                // 19 december 2020
//                let checkpointStr = "000000208165a75ded05f0f65e4c8ebf78b2cc0259a4eb67ef9602000000000000000000aaf6fad57869fe8213b9c90abcf2361486deb5b67b9ad77cf54cd975e7ef1713f416dd5f72130f1726f75daaba190a00ca4f6c4ba0c05dcee4d3df4f5cd25415ba93fd86e44603000000000000000000"
                // 662300 block from 21 december 9:36 am
//                let checkpointStr = "0000002085c76b3d6dc06033bb22731ce4e6a4b39f05beff73be0b000000000000000000a8a812a432bb78098d7d7d6d7fe8bbd2f67e0c607aed00f84727aa69f5e6cbf96226e05f72130f17003593ea1c1b0a0064854daa3957a5baf5e7f8b8121324b5d515428f428c09000000000000000000"
                // 21 december 2020 first tx checkpoint
//                let checkpointStr = "0080f92152088f7109df3b12423a81990fd610be19f7d6bb11dd030000000000000000007dc658abe5011de28a4689e1970ebbb4791dd01dc78e12ec26a1305e9262187330aee05f72130f178bfab7865a1b0a00e7c947de3a4f2ad97a35d9b5fe5451160dcab72c50f209000000000000000000"
                
                // 17 November 2020
                let checkpointStr = "00000020efb9055f8966b310e99406452e6dc57d1c3e9b438603090000000000000000008a40590caebddbf48ba71fcb180bfdca8e35c62d51d3fa7834d03a53a098e73987b0b25fddfe0f176257943840070a003417196318ab69c8526d79b11a4dd5aa7e3e9259d2a604000000000000000000"
                
                // 16 december 2020 16:47
//                 let checkpointStr = "0000c02062d0274c11818584cb22126da68c8d5d00d7da1699a40600000000000000000031623d5dd73c9af09dfef548f8d5d2a1cf3fc6776e947034f44fa43ef22f4c096901da5f72130f179e8f863e71180a00c9b5ae25f10fa8d80c318e87d7d2df5f5cbc1d2b812002000000000000000000"
                let checkpoint = try! Checkpoint(string: checkpointStr)
                let spvAdapter = SpvAdapter(networkType: testnet ? .testNet : .mainNet,
                                            walletPublicKey: walletPublicKey,
                                            compressedWalletPublicKey: compressedPubKey,
                                            bip: bip,
                                            syncCheckpoint: checkpoint,
                                            syncMode: .newWallet,
                                            logger: Logger(minLogLevel: .verbose))
//                let bitcoinManager = BitcoinManager(networkParams: network.networkParams,
//                                                             walletPublicKey: walletPublicKey,
//                                                             compressedWalletPublicKey: compressedPubKey,
//                                                             bip: bip)
                let bitcoinManager = BitcoinManager(networkParams: network.networkParams,
                                                    walletPublicKey: walletPublicKey,
                                                    compressedWalletPublicKey: compressedPubKey,
                                                    kit: spvAdapter.bitcoinKit.bitcoinCore)
                
                $0.txBuilder = BitcoinTransactionBuilder(bitcoinManager: bitcoinManager, addresses: addresses)
                $0.spv = spvAdapter
                
                var providers = [BitcoinNetworkApi:BitcoinNetworkProvider]()
                providers[.blockchair] = BlockchairProvider(endpoint: .bitcoin, apiKey: config.blockchairApiKey)
                providers[.blockcypher] = BlockcypherProvider(endpoint: BlockcypherEndpoint(coin: .btc, chain: testnet ? .test3: .main),
                                                              tokens: config.blockcypherTokens)
               // providers[.main] = BitcoinMainProvider()
                
                $0.networkService = BitcoinNetworkService(providers: providers, isTestNet: testnet, defaultApi: .blockchair)
            }
            
        case .litecoin:
            return LitecoinWalletManager(cardId: cardId, wallet: wallet).then {
                let bitcoinManager = BitcoinManager(networkParams: LitecoinNetworkParams(),
                                                    walletPublicKey: walletPublicKey,
                                                    compressedWalletPublicKey: Secp256k1Utils.convertKeyToCompressed(walletPublicKey)!,
                                                    bip: .bip44)
                
                $0.txBuilder = BitcoinTransactionBuilder(bitcoinManager: bitcoinManager, addresses: addresses)
                
                var providers = [BitcoinNetworkApi:BitcoinNetworkProvider]()
                providers[.blockcypher] = BlockcypherProvider(endpoint: BlockcypherEndpoint(coin: .ltc, chain: .main), tokens: config.blockcypherTokens)
                providers[.blockchair] = BlockchairProvider(endpoint: .litecoin, apiKey: config.blockchairApiKey)

                $0.networkService = BitcoinNetworkService(providers: providers, isTestNet: false, defaultApi: .blockchair)
            }
            
        case .ducatus:
            return DucatusWalletManager(cardId: cardId, wallet: wallet).then {
                let bitcoinManager = BitcoinManager(networkParams: DucatusNetworkParams(), walletPublicKey: walletPublicKey, compressedWalletPublicKey: Secp256k1Utils.convertKeyToCompressed(walletPublicKey)!, bip: .bip44)
                
                $0.txBuilder = BitcoinTransactionBuilder(bitcoinManager: bitcoinManager, addresses: addresses)
                $0.networkService = DucatusNetworkService()
            }
            
        case .stellar(let testnet):
            return StellarWalletManager(cardId: cardId, wallet: wallet, cardTokens: tokens).then {
                let url = testnet ? "https://horizon-testnet.stellar.org" : "https://horizon.stellar.org"
                let stellarSdk = StellarSDK(withHorizonUrl: url)
                $0.stellarSdk = stellarSdk
                $0.txBuilder = StellarTransactionBuilder(stellarSdk: stellarSdk, walletPublicKey: walletPublicKey, isTestnet: testnet)
                $0.networkService = StellarNetworkService(stellarSdk: stellarSdk)
            }
            
        case .ethereum(let testnet):
            return EthereumWalletManager(cardId: cardId, wallet: wallet, cardTokens: tokens).then {
                let ethereumNetwork = testnet ? EthereumNetwork.testnet(projectId: config.infuraProjectId) : EthereumNetwork.mainnet(projectId: config.infuraProjectId)
                $0.txBuilder = EthereumTransactionBuilder(walletPublicKey: walletPublicKey, network: ethereumNetwork)
                let provider = BlockcypherProvider(endpoint: .init(coin: .eth, chain: .main), tokens: config.blockcypherTokens)
                $0.networkService = EthereumNetworkService(network: ethereumNetwork, blockcypherProvider: provider)
            }
            
        case .rsk:
            return EthereumWalletManager(cardId: cardId, wallet: wallet, cardTokens: tokens).then {
                $0.txBuilder = EthereumTransactionBuilder(walletPublicKey: walletPublicKey, network: .rsk)
                $0.networkService = EthereumNetworkService(network: .rsk, blockcypherProvider: nil)
            }
            
        case .bitcoinCash(let testnet):
            return BitcoinCashWalletManager(cardId: cardId, wallet: wallet).then {
                let provider = BlockchairProvider(endpoint: .bitcoinCash, apiKey: config.blockchairApiKey)
                $0.txBuilder = BitcoinCashTransactionBuilder(walletPublicKey: walletPublicKey, isTestnet: testnet)
                $0.networkService = BitcoinCashNetworkService(provider: provider)
            }
            
        case .binance(let testnet):
            return BinanceWalletManager(cardId: cardId, wallet: wallet, cardTokens: tokens).then {
                $0.txBuilder = BinanceTransactionBuilder(walletPublicKey: walletPublicKey, isTestnet: testnet)
                $0.networkService = BinanceNetworkService(isTestNet: testnet)
            }
            
        case .cardano(let shelley):
            return CardanoWalletManager(cardId: cardId, wallet: wallet).then {
                $0.txBuilder = CardanoTransactionBuilder(walletPublicKey: walletPublicKey, shelleyCard: shelley)
                $0.networkService = CardanoNetworkService()
            }
            
        case .xrp(let curve):
            return XRPWalletManager(cardId: cardId, wallet: wallet).then {
                $0.txBuilder = XRPTransactionBuilder(walletPublicKey: walletPublicKey, curve: curve)
                $0.networkService = XRPNetworkService()
            }
        case .tezos:
            return TezosWalletManager(cardId: cardId, wallet: wallet).then {
                $0.txBuilder = TezosTransactionBuilder(walletPublicKey: walletPublicKey)
                $0.networkService = TezosNetworkService()
            }
        }
    }
	
    public func isBlockchainSupported(_ card: Card) -> Bool {
        guard let blockchainName = card.cardData?.blockchainName,
            let curve = card.curve,
            let _ = Blockchain.from(blockchainName: blockchainName, curve: curve) else {
                return false
        }
        
        return true
    }
	
	private func getBlockchain(from card: Card) -> Blockchain? {
		guard let blockchainName = card.cardData?.blockchainName,
			let curve = card.curve,
			let blockchain = Blockchain.from(blockchainName: blockchainName, curve: curve)
		else {
			return nil
		}
		return blockchain
	}
    
    private func getToken(from card: Card) -> Token? {
        if let symbol = card.cardData?.tokenSymbol,
            let contractAddress = card.cardData?.tokenContractAddress,
            let decimal = card.cardData?.tokenDecimal {
            return Token(symbol: symbol,
                             contractAddress: contractAddress,
                             decimalCount: decimal)
        }
        return nil
    }
}
