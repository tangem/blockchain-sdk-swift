//
//  AptosWalletManager.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 25.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class AptosWalletManager: BaseManager {
    
    // MARK: - Private Properties

    private let transactionBuilder: AptosTransactionBuilder
    private let networkService: AptosNetworkService
    
    // MARK: - Init
    
    init(wallet: Wallet, transactionBuilder: AptosTransactionBuilder, networkService: AptosNetworkService) {
        self.transactionBuilder = transactionBuilder
        self.networkService = networkService
        super.init(wallet: wallet)
    }
    
    // MARK: - Implementation
    
    override func update(completion: @escaping (Result<Void, Error>) -> Void) {
        cancellable = networkService
            .getAccount(address: wallet.address)
            .sink(
                receiveCompletion: { [unowned self] completionSubscription in
                    if case let .failure(error) = completionSubscription {
                        self.wallet.amounts = [:]
                        completion(.failure(error))
                    }
                },
                receiveValue: { [unowned self] accountInfo in
                    self.update(with: accountInfo, completion: completion)
                }
            )
    }
    
}

extension AptosWalletManager: WalletManager {
    
    var currentHost: String {
        networkService.host
    }
    
    var allowsFeeSelection: Bool {
        false
    }
    
    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], Error> {
        networkService
            .getGasUnitPrice()
            .withWeakCaptureOf(self)
            .flatMap { (walletManager, gasUnitPrice) -> AnyPublisher<(estimatedFee: Decimal, gasUnitPrice: UInt64), Error> in
                guard let transactionInfo = try? walletManager.transactionBuilder.buildToCalculateFee(
                    amount: amount,
                    destination: destination,
                    gasUnitPrice: gasUnitPrice
                ) else {
                    return .anyFail(error: WalletError.failedToGetFee)
                }
                
                return walletManager
                    .networkService
                    .calculateUsedGasPriceUnit(info: transactionInfo)
                    .eraseToAnyPublisher()
            }
            .withWeakCaptureOf(self)
            .map { (walletManager, result) -> [Fee] in
                let (estimatedFee, gasUnitPrice) = result
                
                let feeAmount = Amount(with: walletManager.wallet.blockchain, value: estimatedFee)
                
                return [
                    Fee(feeAmount, parameters: AptosFeeParams(gasUnitPrice: gasUnitPrice))
                ]
            }
            .eraseToAnyPublisher()
    }
    
    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<TransactionSendResult, Error> {
        let dataForSign: Data
        
        do {
            dataForSign = try transactionBuilder.buildForSign(transaction: transaction)
        } catch {
            return .anyFail(error: WalletError.failedToBuildTx)
        }
        
        return signer
            .sign(hash: dataForSign, walletPublicKey: self.wallet.publicKey)
            .withWeakCaptureOf(self)
            .flatMap { (walletManager, signature) -> AnyPublisher<String, Error> in
                guard let buildForSend = try? self.transactionBuilder.buildForSend(transaction: transaction, signature: signature) else {
                    return .anyFail(error: WalletError.failedToSendTx)
                }
                
                return walletManager.networkService.submitTransaction(data: buildForSend)
            }
            .withWeakCaptureOf(self)
            .map { walletManager, transactionHash in
                let mapper = PendingTransactionRecordMapper()
                let record = mapper.mapToPendingTransactionRecord(transaction: transaction, hash: transactionHash)
                walletManager.wallet.addPendingTransaction(record)
                return TransactionSendResult(hash: transactionHash)
            }
            .eraseToAnyPublisher()
    }
    
}

// MARK: - Private Implementation

private extension AptosWalletManager {
    func update(with accountModel: AptosAccountInfo, completion: @escaping (Result<Void, Error>) -> Void) {
        wallet.add(coinValue: accountModel.balance)

        if accountModel.sequenceNumber != transactionBuilder.currentSequenceNumber {
            wallet.clearPendingTransaction()
        }
        
        transactionBuilder.update(sequenceNumber: accountModel.sequenceNumber)

        completion(.success(()))
    }
}