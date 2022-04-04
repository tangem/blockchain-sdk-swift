//
//  BinanceWalletManager.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 15.02.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BinanceChain
import struct TangemSdk.SignResponse

class BinanceWalletManager: BaseManager, WalletManager {
    var txBuilder: BinanceTransactionBuilder!
    var networkService: BinanceNetworkService!
    private var latestTxDate: Date?
    
    var currentHost: String { networkService.host }
    
    func update(completion: @escaping (Result<Void, Error>)-> Void) {
        cancellable = networkService
            .getInfo(address: wallet.address)
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
    
    private func updateWallet(with response: BinanceInfoResponse) {
        let blockchain = wallet.blockchain
        let coinBalance = response.balances[blockchain.currencySymbol] ?? 0 //if withdrawal all funds, there is no balance from network
        wallet.add(coinValue: coinBalance)
        
        if cardTokens.isEmpty {
            response.balances
                .filter { $0.key != blockchain.currencySymbol }
                .forEach { response in
                    let symbol = response.key.split(separator: "-").first.map {String($0)} ?? response.key
                    let token = Token(name: symbol,
                                      symbol: symbol,
                                      contractAddress: response.key,
                                      decimalCount: blockchain.decimalCount)
                    wallet.add(tokenValue: response.value, for: token)
                }
        } else {
            for token in cardTokens {
                let balance = response.balances[token.contractAddress] ?? 0 //if withdrawal all funds, there is no balance from network
                wallet.add(tokenValue: balance, for: token)
            }
        }
        
        txBuilder.binanceWallet.sequence = response.sequence
        txBuilder.binanceWallet.accountNumber = response.accountNumber
        
        let currentDate = Date()
        for index in wallet.transactions.indices {
            if DateInterval(start: wallet.transactions[index].date!, end: currentDate).duration > 10 {
                wallet.transactions[index].status = .confirmed
            }
        }
    }
}

extension BinanceWalletManager: TransactionSender {
    var allowsFeeSelection: Bool { false }
    
    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<Void, Error> {
        guard let msg = txBuilder.buildForSign(transaction: transaction) else {
            return Fail(error: WalletError.failedToBuildTx).eraseToAnyPublisher()
        }
        
        let hash = msg.encodeForSignature()
        return signer.sign(hash: hash,
                           cardId: wallet.cardId,
                           walletPublicKey: self.wallet.publicKey)
            .tryMap {[weak self] signature -> Message in
                guard let self = self else { throw WalletError.empty }
                
                guard let tx = self.txBuilder.buildForSend(signature: signature, hash: hash) else {
                    throw WalletError.failedToBuildTx
                }
                return tx
            }
            .flatMap {[weak self] tx -> AnyPublisher<Void, Error> in
                self?.networkService.send(transaction: tx).tryMap {[weak self] response in
                    guard let self = self else { throw WalletError.empty }
                    
                    self.wallet.add(transaction: transaction)
                    self.latestTxDate = Date()
                }.eraseToAnyPublisher() ?? .emptyFail
            }
            .eraseToAnyPublisher()
    }
    
    func getFee(amount: Amount,  destination: String) -> AnyPublisher<[Amount], Error> {
        return networkService.getFee()
            .tryMap {[weak self] feeString throws -> [Amount] in
                guard let self = self else { throw WalletError.empty }
                
                guard let feeValue = Decimal(feeString) else {
                    throw WalletError.failedToGetFee
                }
                
                return [Amount(with: self.wallet.blockchain, value: feeValue)]
            }
            .eraseToAnyPublisher()
    }
}

extension BinanceWalletManager: ThenProcessable { }
