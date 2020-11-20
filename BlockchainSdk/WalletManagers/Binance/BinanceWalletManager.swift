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
        wallet.add(coinValue: Decimal(response.balance))
        if let assetBalance = response.assetBalance {
            wallet.add(tokenValue: Decimal(assetBalance))
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

@available(iOS 13.0, *)
extension BinanceWalletManager: TransactionSender {
    var allowsFeeSelection: Bool { false }
    
    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<SignResponse, Error> {
        guard let msg = txBuilder.buildForSign(transaction: transaction) else {
            return Fail(error: WalletError.failedToBuildTx).eraseToAnyPublisher()
        }
        
        let hash = msg.encodeForSignature()
        return signer.sign(hashes: [hash], cardId: cardId)
            .tryMap {[unowned self] response -> (Message, SignResponse) in
                guard let tx = self.txBuilder.buildForSend(signature: response.signature, hash: hash) else {
                    throw WalletError.failedToBuildTx
                }
                return (tx, response)
        }
        .flatMap {[unowned self] values -> AnyPublisher<SignResponse, Error> in
            self.networkService.send(transaction: values.0).map {[unowned self] response in
                self.wallet.add(transaction: transaction)
                self.latestTxDate = Date()
                return values.1
            }.eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }
    
    func getFee(amount: Amount,  destination: String) -> AnyPublisher<[Amount], Error> {
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
