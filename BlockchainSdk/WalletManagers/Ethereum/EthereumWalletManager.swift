//
//  EthereumWalletManager.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 13.12.2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
import web3swift
import Combine
import TangemSdk
import Moya

public enum ETHError: String, Error, LocalizedError {
    case failedToParseTxCount = "eth_tx_count_parse_error"
    case failedToParseBalance = "eth_balance_parse_error"
    case failedToParseTokenBalance = "eth_token_balance_parse_error"
    case failedToParseGasLimit
    case failedToParseGasPrice
    case notValidEthereumValue
    case unsupportedFeature
    
    public var errorDescription: String? {
        switch self {
        case .failedToParseGasLimit:
            return rawValue
        default:
            return rawValue.localized
        }
    }
}

@available(iOS 13.0, *)
public protocol EthereumGasLoader: AnyObject {
    func getGasPrice() -> AnyPublisher<BigUInt, Error>
    func getGasLimit(amount: Amount, destination: String) -> AnyPublisher<BigUInt, Never>
}

public protocol EthereumTransactionSigner: AnyObject {
    func sign(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<String, Error>
}

class EthereumWalletManager: WalletManager {
    var txBuilder: EthereumTransactionBuilder!
    var networkService: EthereumNetworkService!
    
    var txCount: Int = -1
    var pendingTxCount: Int = -1
    
    override var currentHost: String {
        networkService.host
    }
    
    private var gasLimit: BigUInt? = nil
    private var findTokensSubscription: AnyCancellable? = nil
    
    override func update(completion: @escaping (Result<Void, Error>)-> Void) {
        cancellable = networkService
            .getInfo(address: wallet.address, tokens: cardTokens)
            .sink(receiveCompletion: {[unowned self] completionSubscription in
                if case let .failure(error) = completionSubscription {
                    self.wallet.amounts = [:]
                    completion(.failure(error))
                }
            }, receiveValue: { [unowned self] response in
                self.updateWallet(with: response)
                completion(.success(()))
            })
    }
    
    override public func addToken(_ token: Token) -> AnyPublisher<Amount, Error> {
        if !cardTokens.contains(token) {
            cardTokens.append(token)
        }
        
        return networkService.getTokensBalance(wallet.address, tokens: [token])
            .tryMap { [unowned self] result throws -> Amount in
                guard let value = result[token] else {
                    throw WalletError.failedToLoadTokenBalance(token: token)
                }
                let tokenAmount = wallet.add(tokenValue: value, for: token)
                return tokenAmount
            }
            .eraseToAnyPublisher()
    }
    
    private func updateWallet(with response: EthereumInfoResponse) {
        wallet.add(coinValue: response.balance)
        for tokenBalance in response.tokenBalances {
            wallet.add(tokenValue: tokenBalance.value, for: tokenBalance.key)
        }
        txCount = response.txCount
        pendingTxCount = response.pendingTxCount

        if !response.pendingTxs.isEmpty {
            wallet.transactions.removeAll()
            response.pendingTxs.forEach {
                wallet.addPendingTransaction($0)
            }
        } else if txCount == pendingTxCount {
            for  index in wallet.transactions.indices {
                wallet.transactions[index].status = .confirmed
            }
        } else {
            if wallet.transactions.isEmpty {
                wallet.addDummyPendingTransaction()
            }
        }
    }
    
    private func getFixedGasLimit(for amount: Amount) -> BigUInt {
        if amount.type == .coin {
            return GasLimit.default.value
        }
        
        if amount.currencySymbol == "DGX" {
            return GasLimit.high.value
        }
        
        if amount.currencySymbol == "AWG" {
            return GasLimit.medium.value
        }
        
        return GasLimit.erc20.value
    }
    
    private func formatDestinationInfo(for destination: String, amount: Amount) -> (to: String, data: String?) {
        var to = destination
        var data: String? = nil
        
        if let token = amount.type.token, let erc20Data = txBuilder.getData(for: amount, targetAddress: destination) {
            to = token.contractAddress
            data = "0x" + erc20Data.hexString
        }
        
        return (to, data)
    }
}

extension EthereumWalletManager: TransactionSender {
    var allowsFeeSelection: Bool { true }
    
    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<Void, Error> {
        sign(transaction, signer: signer)
            .flatMap {[unowned self] tx -> AnyPublisher<Void, Error> in
                self.networkService.send(transaction: tx).map {[unowned self] sendResponse in
                    var tx = transaction
                    tx.hash = sendResponse
                    self.wallet.add(transaction: tx)
                }.eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Amount],Error> {
        let destinationInfo = formatDestinationInfo(for: destination, amount: amount)
        return networkService.getFee(to: destinationInfo.to, from: wallet.address, data: destinationInfo.data, fallbackGasLimit: getFixedGasLimit(for: amount))
            .tryMap {
                guard $0.fees.count == 3 else {
                    throw BlockchainSdkError.failedToLoadFee
                }
                self.gasLimit = $0.gasLimit
                
                let minAmount = Amount(with: self.wallet.blockchain, value: $0.fees[0])
                let normalAmount = Amount(with: self.wallet.blockchain, value: $0.fees[1])
                let maxAmount = Amount(with: self.wallet.blockchain, value: $0.fees[2])
                
                return [minAmount, normalAmount, maxAmount]
            }
            .eraseToAnyPublisher()
    }
    
}

extension EthereumWalletManager: EthereumTransactionSigner {
    func sign(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<String, Error> {
        guard let txForSign = txBuilder.buildForSign(transaction: transaction,
                                                     nonce: txCount,
                                                     gasLimit: gasLimit ?? getFixedGasLimit(for: transaction.amount)) else {
            return Fail(error: WalletError.failedToBuildTx).eraseToAnyPublisher()
        }
        
        return signer.sign(hash: txForSign.hash, cardId: wallet.cardId, walletPublicKey: wallet.publicKey)
            .tryMap {[unowned self] signature throws -> String in
                guard let tx = self.txBuilder.buildForSend(transaction: txForSign.transaction, hash: txForSign.hash, signature: signature) else {
                    throw WalletError.failedToBuildTx
                }
                return "0x\(tx.toHexString())"
            }
            .eraseToAnyPublisher()
    }
}

extension EthereumWalletManager: EthereumGasLoader {
    func getGasPrice() -> AnyPublisher<BigUInt, Error> {
        networkService.getGasPrice()
    }
    
    func getGasLimit(amount: Amount, destination: String) -> AnyPublisher<BigUInt, Never> {
        let destInfo = formatDestinationInfo(for: destination, amount: amount)
        
        return networkService
            .getGasLimit(to: destInfo.to, from: wallet.address, data: destInfo.data)
            .catch {[unowned self] error -> Just<BigUInt> in
                print(error)
                return Just(self.getFixedGasLimit(for: amount))
            }
            .eraseToAnyPublisher()
    }
}

extension EthereumWalletManager: SignatureCountValidator {
	func validateSignatureCount(signedHashes: Int) -> AnyPublisher<Void, Error> {
		networkService.getSignatureCount(address: wallet.address)
			.tryMap {
				if signedHashes != $0 { throw BlockchainSdkError.signatureCountNotMatched }
			}
			.eraseToAnyPublisher()
	}
}

extension EthereumWalletManager: ThenProcessable { }

extension EthereumWalletManager {
    enum GasLimit: Int {
        case `default` = 21000
        case erc20 = 60000
        case medium = 150000
        case high = 300000
        
        var value: BigUInt {
            return BigUInt(self.rawValue)
        }
    }
}

extension EthereumWalletManager: TokenFinder {
    func findErc20Tokens(knownTokens: [Token], completion: @escaping (Result<Bool, Error>)-> Void) {
        findTokensSubscription?.cancel()
        findTokensSubscription = networkService
            .findErc20Tokens(address: wallet.address)
            .sink(receiveCompletion: { subscriptionCompletion in
                if case let .failure(error) = subscriptionCompletion {
                    completion(.failure(error))
                    return
                }
            }, receiveValue: {[unowned self] blockchairTokens in
                if blockchairTokens.isEmpty {
                    completion(.success(false))
                    return
                }
                
                var tokensAdded = false
                blockchairTokens.forEach { blockchairToken in
                    let foundToken = Token(blockchairToken, blockchain: self.wallet.blockchain)
                    if !self.cardTokens.contains(foundToken) {
                        let token: Token = knownTokens.first(where: { $0 == foundToken }) ?? foundToken
                        self.cardTokens.append(token)
                        let balanceValue = Decimal(blockchairToken.balance) ?? 0
                        let balanceWeiValue = balanceValue / pow(Decimal(10), blockchairToken.decimals)
                        self.wallet.add(tokenValue: balanceWeiValue, for: token)
                        tokensAdded = true
                    }
                }
                
                completion(.success(tokensAdded))
            })
    }
}
