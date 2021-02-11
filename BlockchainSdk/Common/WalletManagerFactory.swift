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
        
        let tkns: [Token]
        let canManageTokens: Bool
        if let cardTokens = getToken(from: card).map({ [$0] }) {
            tkns = cardTokens
            canManageTokens = false
        } else {
            tkns = tokens ?? []
            canManageTokens = true
        }
         
		return makeWalletManager(from: blockchain, walletPublicKey: walletPublicKey, cardId: cardId, walletPairPublicKey: pairKey, tokens: tkns, canManageTokens: canManageTokens)
	}
	
    public func makeWalletManager(from blockchain: Blockchain, walletPublicKey: Data, cardId: String, walletPairPublicKey: Data? = nil, tokens: [Token] = [], canManageTokens: Bool) -> WalletManager {
		let addresses = blockchain.makeAddresses(from: walletPublicKey, with: walletPairPublicKey)
		let wallet = Wallet(blockchain: blockchain,
                            addresses: addresses)
		
        switch blockchain {
        case .bitcoin(let testnet):
            return BitcoinWalletManager(cardId: cardId, wallet: wallet).then {
                let network: BitcoinNetwork = testnet ? .testnet : .mainnet
                let bitcoinManager = BitcoinManager(networkParams: network.networkParams,
                                                             walletPublicKey: walletPublicKey,
                                                             compressedWalletPublicKey: Secp256k1Utils.convertKeyToCompressed(walletPublicKey)!,
                                                             bip: walletPairPublicKey == nil ? .bip84 : .bip141)
                
                $0.txBuilder = BitcoinTransactionBuilder(bitcoinManager: bitcoinManager, addresses: addresses)
                
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
            return EthereumWalletManager(cardId: cardId, wallet: wallet, cardTokens: tokens, canManageTokens: canManageTokens).then {
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
