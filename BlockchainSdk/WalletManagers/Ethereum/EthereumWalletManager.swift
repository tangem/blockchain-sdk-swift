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

class EthereumWalletManager: WalletManager {
    var txBuilder: EthereumTransactionBuilder!
    var networkService: EthereumNetworkService!
    var txCount: Int = -1
    var pendingTxCount: Int = -1
    
    private var gasLimit: BigUInt? = nil
    
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
    
    private func updateWallet(with response: EthereumResponse) {
        wallet.add(coinValue: response.balance)
        for tokenBalance in response.tokenBalances {
            wallet.add(tokenValue: tokenBalance.value, for: tokenBalance.key)
        }
        txCount = response.txCount
        pendingTxCount = response.pendingTxCount
        if txCount == pendingTxCount {
            for  index in wallet.transactions.indices {
                wallet.transactions[index].status = .confirmed
            }
        } else {
            if wallet.transactions.isEmpty {
                wallet.addPendingTransaction()
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
}

@available(iOS 13.0, *)
extension EthereumWalletManager: TransactionSender {
    var allowsFeeSelection: Bool { true }
    
    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<SignResponse, Error> {
        guard let txForSign = txBuilder.buildForSign(transaction: transaction,
                                                     nonce: txCount,
                                                     gasLimit: gasLimit ?? getFixedGasLimit(for: transaction.amount)) else {
            return Fail(error: WalletError.failedToBuildTx).eraseToAnyPublisher()
        }
        
        return signer.sign(hashes: [txForSign.hash], cardId: self.cardId)
            .tryMap {[unowned self] signResponse throws -> (String, SignResponse) in
                guard let tx = self.txBuilder.buildForSend(transaction: txForSign.transaction, hash: txForSign.hash, signature: signResponse.signature) else {
                    throw WalletError.failedToBuildTx
                }
                return ("0x\(tx.toHexString())", signResponse)
        }
        .flatMap {[unowned self] buildResponse -> AnyPublisher<SignResponse, Error> in
            self.networkService.send(transaction: buildResponse.0).map {[unowned self] sendResponse in
                self.wallet.add(transaction: transaction)
                return buildResponse.1
            }.eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }
    
    func getFee(amount: Amount, destination: String, includeFee: Bool) -> AnyPublisher<[Amount],Error> {
        return networkService
            .getGasPrice()
            .combineLatest(getGasLimit(amount: amount, destination: destination).setFailureType(to: Error.self))
            .tryMap { [unowned self] gasPrice, gasLimit throws -> [Amount] in
                self.gasLimit = gasLimit
                let decimalCount = self.wallet.blockchain.decimalCount
                let minValue = gasPrice * gasLimit
                let min = Web3.Utils.formatToEthereumUnits(minValue, toUnits: .eth, decimals: decimalCount, decimalSeparator: ".", fallbackToScientific: false)!
                
                let normalValue = gasPrice * BigUInt(12) / BigUInt(10) * gasLimit
                let normal = Web3.Utils.formatToEthereumUnits(normalValue, toUnits: .eth, decimals: decimalCount, decimalSeparator: ".", fallbackToScientific: false)!
                
                let maxValue = gasPrice * BigUInt(15) / BigUInt(10) * gasLimit
                let max = Web3.Utils.formatToEthereumUnits(maxValue, toUnits: .eth, decimals: decimalCount, decimalSeparator: ".", fallbackToScientific: false)!
                
                guard let minDecimal = Decimal(string: min),
                    let normalDecimal = Decimal(string: normal),
                    let maxDecimal = Decimal(string: max) else {
                        throw WalletError.failedToGetFee
                }
                
                let minAmount = Amount(with: self.wallet.blockchain, address: self.wallet.address, value: minDecimal)
                let normalAmount = Amount(with: self.wallet.blockchain, address: self.wallet.address, value: normalDecimal)
                let maxAmount = Amount(with: self.wallet.blockchain, address: self.wallet.address, value: maxDecimal)
                
                return [minAmount, normalAmount, maxAmount]
        }
        .eraseToAnyPublisher()
    }
    
    
    private func getGasLimit(amount: Amount, destination: String) -> AnyPublisher<BigUInt, Never> {
        var to = destination
        var data: String? = nil
        
        if let token = amount.type.token, let erc20Data = txBuilder.getData(for: amount, targetAddress: destination) {
            to = token.contractAddress
            data = "0x" + erc20Data.asHexString()
        }
        
        return networkService
            .getGasLimit(to: to, from: wallet.address, data: data)
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
