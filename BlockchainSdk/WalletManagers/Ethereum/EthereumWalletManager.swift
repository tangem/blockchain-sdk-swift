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

class EthereumWalletManager: WalletManager {
    var txBuilder: EthereumTransactionBuilder!
    var networkService: EthereumNetworkService!
    var txCount: Int = -1
    var pendingTxCount: Int = -1
    
    override func update(completion: @escaping (Result<Void, Error>)-> Void) {
        cancellable = networkService
            .getInfo(address: wallet.address, contractAddress: wallet.token?.contractAddress)
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
        if let tokenBalance = response.tokenBalance {
            wallet.add(tokenValue: tokenBalance)
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
}

@available(iOS 13.0, *)
extension EthereumWalletManager: TransactionSender {
    var allowsFeeSelection: Bool { true }
    
    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<SignResponse, Error> {
        guard let txForSign = txBuilder.buildForSign(transaction: transaction, nonce: txCount) else {
            return Fail(error: EthereumError.failedToBuildHash).eraseToAnyPublisher()
        }
        
        return signer.sign(hashes: [txForSign.hash], cardId: self.cardId)
            .tryMap {[unowned self] signResponse throws -> (String, SignResponse) in
                guard let tx = self.txBuilder.buildForSend(transaction: txForSign.transaction, hash: txForSign.hash, signature: signResponse.signature) else {
                    throw BitcoinError.failedToBuildTransaction
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
    
    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Amount],Error> {
        return networkService.getGasPrice()
            .tryMap { [unowned self] gasPrice throws -> [Amount] in
                let m = self.txBuilder.getGasLimit(for: amount)
                let decimalCount = self.wallet.blockchain.decimalCount
                let minValue = gasPrice * m
                let min = Web3.Utils.formatToEthereumUnits(minValue, toUnits: .eth, decimals: decimalCount, decimalSeparator: ".", fallbackToScientific: false)!
                
                let normalValue = gasPrice * BigUInt(12) / BigUInt(10) * m
                let normal = Web3.Utils.formatToEthereumUnits(normalValue, toUnits: .eth, decimals: decimalCount, decimalSeparator: ".", fallbackToScientific: false)!
                
                let maxValue = gasPrice * BigUInt(15) / BigUInt(10) * m
                let max = Web3.Utils.formatToEthereumUnits(maxValue, toUnits: .eth, decimals: decimalCount, decimalSeparator: ".", fallbackToScientific: false)!
                
                guard let minDecimal = Decimal(string: min),
                    let normalDecimal = Decimal(string: normal),
                    let maxDecimal = Decimal(string: max) else {
                        throw EthereumError.failedToGetFee
                }
                
                let minAmount = Amount(with: self.wallet.blockchain, address: self.wallet.address, value: minDecimal)
                let normalAmount = Amount(with: self.wallet.blockchain, address: self.wallet.address, value: normalDecimal)
                let maxAmount = Amount(with: self.wallet.blockchain, address: self.wallet.address, value: maxDecimal)
                
                return [minAmount, normalAmount, maxAmount]
        }
        .eraseToAnyPublisher()
    }
}

enum EthereumError: Error {
    case failedToGetFee
    case failedToBuildHash
}



extension EthereumWalletManager: ThenProcessable { }
