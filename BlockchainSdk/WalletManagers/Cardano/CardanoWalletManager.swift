//
//  CardanoWalletManager.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 08.04.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk

public enum CardanoError: String, Error, LocalizedError {
    case noUnspents = "cardano_missing_unspents"
    case lowAda = "cardano_low_ada"
     
    public var errorDescription: String? {
        return self.rawValue.localized
    }
}

class CardanoWalletManager: WalletManager {
    var txBuilder: CardanoTransactionBuilder!
    var networkService: AdaliteProvider!
    
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
    
    private func updateWallet(with response: (AdaliteBalanceResponse,[AdaliteUnspentOutput])) {
        wallet.add(coinValue: response.0.balance)
        txBuilder.unspentOutputs = response.1
        let respTxs = response.0.transactionList
        
        wallet.transactions = wallet.transactions.compactMap { pendingTx in
            if respTxs.isEmpty {
                
            }
            if let pendingTxHash = pendingTx.hash {
                if response.0.transactionList.contains(pendingTxHash.lowercased()) {
                    return nil
                }
            }
            return pendingTx
        }
        
        
//        wallet.recentTransactions.forEach { recentTransaction ->
//                    if (response.recentTransactionsHashes.isEmpty()) { // case for Rosetta API, it lacks recent transactions
//                        if (response.unspentOutputs.isEmpty() ||
//                                response.unspentOutputs.find {
//                                    it.transactionHash.toHexString()
//                                            .equals(recentTransaction.hash, ignoreCase = true)
//                                } != null
//                        ) {
//                            recentTransaction.status = TransactionStatus.Confirmed
//                        }
//                    } else { // case for APIs with recent transactions
//                        if (response.recentTransactionsHashes
//                                        .find { it.equals(recentTransaction.hash, true) } != null
//                        ) {
//                            recentTransaction.status = TransactionStatus.Confirmed
//                        }
//                    }
//                }
    }
}

@available(iOS 13.0, *)
extension CardanoWalletManager: TransactionSender {
    var allowsFeeSelection: Bool { false }
    
    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<SignResponse, Error> {
        guard let walletAmount = wallet.amounts[.coin]?.value else {
            return Fail(error: WalletError.failedToBuildTx).eraseToAnyPublisher()
        }
        
        let txBuildResult = txBuilder.buildForSign(transaction: transaction, walletAmount: walletAmount, isEstimated: false)
        switch txBuildResult {
        case .success(let info):
            return signer.sign(hashes: [info.hash], cardId: cardId)
                .tryMap {[unowned self] response -> (tx: Data, hash: String, signResponse: SignResponse) in
                    let txBuildForSendResult = self.txBuilder.buildForSend(bodyItem: info.bodyItem, signature: response.signature)
                    switch txBuildForSendResult {
                    case .failure(let error):
                        throw error
                    case .success(let tx):
                        return (tx, info.hash.asHexString(), response)
                    }
            }
            .flatMap {[unowned self] builderResponse -> AnyPublisher<SignResponse, Error> in
                self.networkService.send(base64EncodedTx: builderResponse.tx.base64EncodedString()).map {[unowned self] response in
                    var sendedTx = transaction
                    sendedTx.hash = builderResponse.hash
                    self.wallet.add(transaction: sendedTx)
                    return builderResponse.signResponse
                }.eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
        case .failure(let error):
            return Fail(error: error).eraseToAnyPublisher()
        }
    }
    
    func getFee(amount: Amount, destination: String, includeFee: Bool) -> AnyPublisher<[Amount], Error> {
        guard let transactionSize = self.getEstimateSize(amount: amount, destination: destination) else {
            return Fail(error: WalletError.failedToCalculateTxSize).eraseToAnyPublisher()
        }
        
        let a = Decimal(0.155381)
        let b = Decimal(0.000044)
        
        let feeValue = (a + b * transactionSize).rounded(blockchain: wallet.blockchain)
        let feeAmount = Amount(with: self.wallet.blockchain, address: self.wallet.address, value: feeValue)
        return Result.Publisher([feeAmount]).eraseToAnyPublisher()
    }
    
    private func getEstimateSize(amount: Amount, destination: String) -> Decimal? {
        let dummyFee = Amount(with: self.wallet.blockchain, address: self.wallet.address, value: Decimal(0.1))
        let dummyAmount = amount - dummyFee
        let dummyTx = Transaction(amount: dummyAmount,
                                  fee: dummyFee,
                                  sourceAddress: self.wallet.address,
                                  destinationAddress: destination,
                                  changeAddress: self.wallet.address)
        
        
        guard let walletAmount = wallet.amounts[.coin]?.value else {
            return nil
        }
        
		let txBuildResult = txBuilder.buildForSign(transaction: dummyTx, walletAmount: walletAmount, isEstimated: true)
        guard case let .success(info) = txBuildResult else {
            return nil
        }
        
        let txBuildForSendResult = txBuilder.buildForSend(bodyItem: info.bodyItem, signature: Data(repeating: 0, count: 64))
        guard case let .success(tx) = txBuildForSendResult else {
            return nil
        }

        return Decimal(tx.count)
    }
}

extension CardanoWalletManager: ThenProcessable { }


extension CardanoWalletManager: DustRestrictable {
    var dustValue: Amount {
        return Amount(with: wallet.blockchain, address: wallet.address, value: 1.0)
    }
}
