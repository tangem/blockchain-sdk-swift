//
//  KaspaWalletManager.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 10.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class KaspaWalletManager: BaseManager, WalletManager {
    var txBuilder: KaspaTransactionBuilder!
    var networkService: KaspaNetworkService!
    
    var currentHost: String { networkService.host }
    var allowsFeeSelection: Bool { false }
    
    func update(completion: @escaping (Result<Void, Error>) -> Void) {
        let unconfirmedTransactionHashes = wallet.transactions
            .filter { $0.status == .unconfirmed }
            .compactMap { $0.hash }
        
        cancellable = networkService.getInfo(address: wallet.address, unconfirmedTransactionHashes: unconfirmedTransactionHashes)
            .sink { result in
                switch result {
                case .failure(let error):
                    self.wallet.clearAmounts()
                    completion(.failure(error))
                case .finished:
                    completion(.success(()))
                }
            } receiveValue: { [weak self] response in
                self?.updateWallet(response)
            }
    }
    
    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<TransactionSendResult, Error> {
        let kaspaTransaction: KaspaTransaction
        let hashes: [Data]
        
        do {
            let result = try txBuilder.buildForSign(transaction)
            kaspaTransaction = result.0
            hashes = result.1
        } catch {
            return .anyFail(error: error)
        }
        
        return signer.sign(hashes: hashes, walletPublicKey: wallet.publicKey)
            .tryMap { [weak self] signatures in
                guard let self = self else { throw WalletError.empty }
                
                return self.txBuilder.buildForSend(transaction: kaspaTransaction, signatures: signatures)
            }
            .flatMap { [weak self] tx -> AnyPublisher<KaspaTransactionResponse, Error> in
                guard let self = self else { return .emptyFail }
                
                return self.networkService.send(transaction: KaspaTransactionRequest(transaction: tx))
            }
            .handleEvents(receiveOutput: { [weak self] in
                var submittedTransaction = transaction
                submittedTransaction.hash = $0.transactionId
                self?.wallet.transactions.append(submittedTransaction)
            })
            .map {
                TransactionSendResult(hash: $0.transactionId)
            }
            .eraseToAnyPublisher()
    }
    
    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Amount], Error> {
        let numberOfUtxos = txBuilder.unspentOutputsCount(for: amount)
        guard numberOfUtxos > 0 else {
            return Fail(error: WalletError.failedToGetFee)
                .eraseToAnyPublisher()
        }
        
        let feePerUtxo = 10_000
        let fee = feePerUtxo * numberOfUtxos
        
        return Just([Amount(with: wallet.blockchain, value: Decimal(fee) / wallet.blockchain.decimalValue)])
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    private func updateWallet(_ info: KaspaAddressInfo) {
        self.wallet.add(amount: Amount(with: self.wallet.blockchain, value: info.balance))
        txBuilder.setUnspentOutputs(info.unspentOutputs)
        
        for (index, transaction) in wallet.transactions.enumerated() {
            if let hash = transaction.hash, info.confirmedTransactionHashes.contains(hash) {
                wallet.transactions[index].status = .confirmed
            }
        }
    }
}

extension KaspaWalletManager: ThenProcessable { }

extension KaspaWalletManager: DustRestrictable {
    var dustValue: Amount {
        Amount(with: wallet.blockchain, value: Decimal(0.0001))
    }
}

extension KaspaWalletManager: WithdrawalValidator {
    func validate(_ transaction: Transaction) -> WithdrawalWarning? {
        let amountAvailableToSend = txBuilder.availableAmount() - transaction.fee
        if transaction.amount <= amountAvailableToSend {
            return nil
        }
        
        let amountToReduceBy = transaction.amount - amountAvailableToSend
        
        return WithdrawalWarning(
            warningMessage: "kaspa_withdrawal_message_warning".localized([txBuilder.maxInputCount, amountAvailableToSend.description]),
            reduceMessage: "common_ok".localized,
            suggestedReduceAmount: amountToReduceBy
        )
    }
}
