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
    var networkService: CardanoNetworkProvider!
    
    override var currentHost: String {
        networkService.host
    }
    
    override func update(completion: @escaping (Result<Void, Error>)-> Void) {//check it
        cancellable = networkService
            .getInfo(addresses: wallet.addresses.map { $0.value })
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
    
    private func updateWallet(with response: CardanoAddressResponse) {
        wallet.add(coinValue: response.balance)
        txBuilder.unspentOutputs = response.unspentOutputs
        
        wallet.transactions = wallet.transactions.map {
            var mutableTx = $0
            let hashLowercased = mutableTx.hash?.lowercased()
            if response.recentTransactionsHashes.isEmpty {
                if response.unspentOutputs.isEmpty ||
                    response.unspentOutputs.first(where: { $0.transactionHash.lowercased() == hashLowercased }) != nil {
                    mutableTx.status = .confirmed
                }
            } else {
                if response.recentTransactionsHashes.first(where: { $0.lowercased() == hashLowercased }) != nil {
                    mutableTx.status = .confirmed
                }
            }
            return mutableTx
        }
    }
}

extension CardanoWalletManager: TransactionSender {
    var allowsFeeSelection: Bool { false }
    
    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<Void, Error> {
        guard let walletAmount = wallet.amounts[.coin]?.value else {
            return Fail(error: WalletError.failedToBuildTx).eraseToAnyPublisher()
        }
        
        let txBuildResult = txBuilder.buildForSign(transaction: transaction, walletAmount: walletAmount, isEstimated: false)
        switch txBuildResult {
        case .success(let info):
            return signer.sign(hash: info.hash, cardId: wallet.cardId, walletPublicKey: wallet.publicKey)
                .tryMap {[unowned self] signature -> (tx: Data, hash: String) in
                    let txBuildForSendResult = self.txBuilder.buildForSend(bodyItem: info.bodyItem, signature: signature)
                    switch txBuildForSendResult {
                    case .failure(let error):
                        throw error
                    case .success(let tx):
                        return (tx, info.hash.asHexString())
                    }
            }
            .flatMap {[unowned self] builderResponse -> AnyPublisher<Void, Error> in
                self.networkService.send(transaction: builderResponse.tx).map {[unowned self] response in
                    var sendedTx = transaction
                    sendedTx.hash = builderResponse.hash
                    self.wallet.add(transaction: sendedTx)
                }.eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
        case .failure(let error):
            return Fail(error: error).eraseToAnyPublisher()
        }
    }
    
    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Amount], Error> {
        guard let transactionSize = self.getEstimateSize(amount: amount, destination: destination) else {
            return Fail(error: WalletError.failedToCalculateTxSize).eraseToAnyPublisher()
        }
        
        let a = Decimal(0.155381)
        let b = Decimal(0.000044)
        
        let feeValue = (a + b * transactionSize).rounded(scale: wallet.blockchain.decimalCount, roundingMode: .up)
        let feeAmount = Amount(with: self.wallet.blockchain, value: feeValue)
        return Result.Publisher([feeAmount]).eraseToAnyPublisher()
    }
    
    private func getEstimateSize(amount: Amount, destination: String) -> Decimal? {
        let dummyFee = Amount(with: self.wallet.blockchain, value: Decimal(0.1))
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
        return Amount(with: wallet.blockchain, value: 1.0)
    }
}
