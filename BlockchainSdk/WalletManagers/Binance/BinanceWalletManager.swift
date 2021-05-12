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

class BinanceWalletManager: WalletManager {
    var txBuilder: BinanceTransactionBuilder!
    var networkService: BinanceNetworkService!
    private var latestTxDate: Date?
    
    override func update(completion: @escaping (Result<Void, Error>)-> Void) {//check it
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
        let coinBalance = response.balances[wallet.blockchain.currencySymbol] ?? 0 //if withdrawal all funds, there is no balance from network
        wallet.add(coinValue: coinBalance)
        
        if cardTokens.isEmpty {
            _ = response.balances
                .filter { $0.key != wallet.blockchain.currencySymbol }
                .map { (Token(symbol: $0.key.split(separator: "-").first.map {String($0)} ?? $0.key,
                              contractAddress: $0.key,
                              decimalCount: wallet.blockchain.decimalCount),
                        $0.value) }
                .map { token, balance in
                    wallet.add(tokenValue: balance, for: token)
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
        for  index in wallet.transactions.indices {
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
        return signer.sign(hash: hash, cardId: wallet.cardId, walletPublicKey: wallet.publicKey)
            .tryMap {[unowned self] signature -> Message in
                guard let tx = self.txBuilder.buildForSend(signature: signature, hash: hash) else {
                    throw WalletError.failedToBuildTx
                }
                return tx
        }
        .flatMap {[unowned self] tx -> AnyPublisher<Void, Error> in
            self.networkService.send(transaction: tx).map {[unowned self] response in
                self.wallet.add(transaction: transaction)
                self.latestTxDate = Date()
            }.eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }
    
    func getFee(amount: Amount,  destination: String, includeFee: Bool) -> AnyPublisher<[Amount], Error> {
        return networkService.getFee()
            .tryMap { feeString throws -> [Amount] in
                guard let feeValue = Decimal(feeString) else {
                    throw WalletError.failedToGetFee
                }
                
                return [Amount(with: self.wallet.blockchain, address: self.wallet.address, value: feeValue)]
        }
        .eraseToAnyPublisher()
    }
}

extension BinanceWalletManager: ThenProcessable { }
