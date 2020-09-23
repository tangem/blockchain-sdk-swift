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

enum CardanoError: Error, LocalizedError {
    case noUnspents
    case failedToBuildHash
    case failedToBuildTransaction
    case failedToMapNetworkResponse
    case lowAda
    case failedToCalculateFee
     
    var errorDescription: String? {
        switch self {
        case .lowAda:
            return "cardano_low_ada".localized
        default:
            return "\(self)"
        }
    }
}

class CardanoWalletManager: WalletManager {
    var txBuilder: CardanoTransactionBuilder!
    var networkService: CardanoNetworkService!
    
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
        
        wallet.transactions = wallet.transactions.compactMap { pendingTx in
            if let pendingTxHash = pendingTx.hash {
                if response.0.transactionList.contains(pendingTxHash.lowercased()) {
                    return nil
                }
            }
            return pendingTx
        }
    }
}

@available(iOS 13.0, *)
extension CardanoWalletManager: TransactionSender {
    var allowsFeeSelection: Bool { false }
    
    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<SignResponse, Error> {
        guard let walletAmount = wallet.amounts[.coin]?.value else {
            return Fail(error: CardanoError.failedToBuildHash).eraseToAnyPublisher()
        }
        
        let txBuildResult = txBuilder.buildForSign(transaction: transaction, walletAmount: walletAmount)
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
    
    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Amount], Error> {
        guard let unspentOutputs = txBuilder.unspentOutputs else {
            return Fail(error: CardanoError.noUnspents).eraseToAnyPublisher()
        }
        
        guard let walletAmount = wallet.amounts[amount.type] else {
            return Fail(error: CardanoError.failedToCalculateFee).eraseToAnyPublisher()
        }
        
        
        let outputsNumber = amount == walletAmount ? 1 : 2
        let transactionSize = unspentOutputs.count * 40 + outputsNumber * 65 + 160
        
        let a = Decimal(0.155381)
        let b = Decimal(0.000043946)
        
        let feeValue = a + b * Decimal(transactionSize)
        let feeAmount = Amount(with: self.wallet.blockchain, address: self.wallet.address, value: feeValue)
        return Result.Publisher([feeAmount]).eraseToAnyPublisher()
    }
}

extension CardanoWalletManager: ThenProcessable { }
