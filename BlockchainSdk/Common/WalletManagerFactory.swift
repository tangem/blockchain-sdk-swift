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

public class WalletManagerFactory {
    public init() {}
        
    public func makeWalletManager(from card: Card, tokens: [Token]? = nil) -> WalletManager? {
        guard let blockchain = getBlockchain(from: card),
            let walletPublicKey = card.walletPublicKey,
            let cardId = card.cardId else {
                return nil
        }
        
        let tokens = tokens ?? getToken(from: card).map { [$0] } ?? []
		return makeWalletManager(from: blockchain, walletPublicKey: walletPublicKey, cardId: cardId, tokens: tokens)
	}
	
	public func makeWalletManager(from blockchain: Blockchain, walletPublicKey: Data, cardId: String, tokens: [Token] = []) -> WalletManager {
		let addresses = blockchain.makeAddresses(from: walletPublicKey)
		let wallet = Wallet(blockchain: blockchain,
                            addresses: addresses)
		
        switch blockchain {
        case .bitcoin(let testnet):
            return BitcoinWalletManager(cardId: cardId, wallet: wallet).then {
				$0.txBuilder = BitcoinTransactionBuilder(walletPublicKey: walletPublicKey, isTestnet: testnet, addresses: addresses)
                $0.networkService = BitcoinNetworkService(isTestNet: testnet)
            }
            
        case .litecoin:
            return LitecoinWalletManager(cardId: cardId, wallet: wallet).then {
                $0.txBuilder = BitcoinTransactionBuilder(walletPublicKey: walletPublicKey, isTestnet: false, addresses: addresses)
                $0.networkService = LitecoinNetworkService(isTestNet: false)
            }
            
        case .ducatus:
            return DucatusWalletManager(cardId: cardId, wallet: wallet).then {
                $0.txBuilder = BitcoinTransactionBuilder(walletPublicKey: walletPublicKey, isTestnet: false, addresses: addresses)
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
            let ethereumNetwork = testnet ? EthereumNetwork.testnet : EthereumNetwork.mainnet
            return EthereumWalletManager(cardId: cardId, wallet: wallet, cardTokens: tokens).then {
                $0.txBuilder = EthereumTransactionBuilder(walletPublicKey: walletPublicKey, network: ethereumNetwork)
                $0.networkService = EthereumNetworkService(network: ethereumNetwork)
            }
            
        case .rsk:
            return EthereumWalletManager(cardId: cardId, wallet: wallet, cardTokens: tokens).then {
                $0.txBuilder = EthereumTransactionBuilder(walletPublicKey: walletPublicKey, network: .rsk)
                $0.networkService = EthereumNetworkService(network: .rsk)
            }
            
        case .bitcoinCash(let testnet):
            return BitcoinCashWalletManager(cardId: cardId, wallet: wallet).then {
                $0.txBuilder = BitcoinCashTransactionBuilder(walletPublicKey: walletPublicKey, isTestnet: testnet)
                $0.networkService = BitcoinCashNetworkService()
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
	
	public func makeMultisigWallet(from card: Card, with pairKey: Data, tokens: [Token]? = nil) -> WalletManager? {
		guard let blockchain = getBlockchain(from: card),
			let walletPublicKey = card.walletPublicKey,
			let cardId = card.cardId else {
				return nil
		}
		
		let tokens = tokens ?? getToken(from: card).map { [$0] } ?? []
		return makeMultisigWallet(from: blockchain, walletPublicKey: walletPublicKey, walletPairPublicKey: pairKey, cardId: cardId, tokens: tokens)
	}
	
	public func makeMultisigWallet(from blockchain: Blockchain, walletPublicKey: Data, walletPairPublicKey: Data, cardId: String, tokens: [Token] = []) -> WalletManager? {
		guard let addresses = blockchain.makeMultisigAddresses(from: walletPublicKey, with: walletPairPublicKey) else { return nil }
		let wallet = Wallet(blockchain: blockchain, addresses: addresses)
		
		switch blockchain {
		case .bitcoin(let testnet):
			return BitcoinWalletManager(cardId: cardId, wallet: wallet).then {
				$0.txBuilder = BitcoinTransactionBuilder(walletPublicKey: walletPublicKey, isTestnet: testnet, addresses: addresses)
				$0.networkService = BitcoinNetworkService(isTestNet: testnet)
			}
		default:
			return nil
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
