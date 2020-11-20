//
//  Bitcoin.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 06.12.2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import Combine

class BitcoinWalletManager: WalletManager {
    var allowsFeeSelection: Bool { true }
    var txBuilder: BitcoinTransactionBuilder!
    var networkService: BitcoinNetworkProvider!
    var relayFee: Decimal? {
        return nil
    }
    
    override var defaultChangeAddress: String {
        wallet.addresses.first {
            ($0 as! BitcoinAddress).type == .bech32
            }!.value
    }
    
    override func update(completion: @escaping (Result<Void, Error>)-> Void)  {
        cancellable = networkService.getInfo()
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
    
    @available(iOS 13.0, *)
    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Amount], Error> {
        return networkService.getFee()
            .tryMap {[unowned self] response throws -> [Amount] in
                let kb = Decimal(1024)
                let minPerByte = response.minimalKb/kb
                let normalPerByte = response.normalKb/kb
                let maxPerByte = response.priorityKb/kb
                let dummyFee = Amount(with: amount, value: 0.00000001)
                guard let estimatedTxSize = self.getEstimateSize(for: Transaction(amount: amount - dummyFee, fee: dummyFee, sourceAddress: self.wallet.address, destinationAddress: destination)) else {
                    throw WalletError.failedToCalculateTxSize
                }
                
                var minFee = (minPerByte * estimatedTxSize)
                var normalFee = (normalPerByte * estimatedTxSize)
                var maxFee = (maxPerByte * estimatedTxSize)
                
                if let relayFee = self.relayFee {
                    minFee = max(minFee, relayFee)
                    normalFee = max(normalFee, relayFee)
                    maxFee = max(maxFee, relayFee)
                }
                
                return [
                    Amount(with: self.wallet.blockchain, address: self.wallet.address, value: minFee),
                    Amount(with: self.wallet.blockchain, address: self.wallet.address, value: normalFee),
                    Amount(with: self.wallet.blockchain, address: self.wallet.address, value: maxFee)
                ]
        }
        .eraseToAnyPublisher()
    }
    
    func updateWallet(with response: BitcoinResponse) {
        wallet.add(coinValue: response.balance)
        txBuilder.unspentOutputs = response.txrefs
        if response.hasUnconfirmed {
            if wallet.transactions.isEmpty {
                wallet.addPendingTransaction()
            }
        } else {
            wallet.transactions = []
        }
    }
    
    private func getEstimateSize(for transaction: Transaction) -> Decimal? {
        guard let unspentOutputsCount = txBuilder.unspentOutputs?.count else {
            return nil
        }
        
        guard let tx = txBuilder.buildForSend(transaction: transaction, signature: Data(repeating: UInt8(0x80), count: 64 * unspentOutputsCount)) else {
            return nil
        }
        
        return Decimal(tx.count)
    }
}


@available(iOS 13.0, *)
extension BitcoinWalletManager: TransactionSender {
    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<SignResponse, Error> {
        guard let hashes = txBuilder.buildForSign(transaction: transaction) else {
            return Fail(error: WalletError.failedToBuildTx).eraseToAnyPublisher()
        }
        
        return signer.sign(hashes: hashes, cardId: cardId)
            .tryMap {[unowned self] response -> (String, SignResponse) in
                guard let tx = self.txBuilder.buildForSend(transaction: transaction, signature: response.signature) else {
                    throw WalletError.failedToBuildTx
                }
                return (tx.toHexString(), response)
        }
        .flatMap {[unowned self] values -> AnyPublisher<SignResponse, Error> in
            return self.networkService.send(transaction: values.0)
                .map {[unowned self] sendResponse in
                    self.wallet.add(transaction: transaction)
                    return values.1
            }.eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }
}

extension BitcoinWalletManager: ThenProcessable { }

