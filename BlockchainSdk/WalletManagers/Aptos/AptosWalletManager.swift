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
        true
    }
    
    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<TransactionSendResult, Error> {
        // TODO: - Make implementation after created transaction builder
        return .anyFail(error: WalletError.failedToSendTx)
    }
    
    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], Error> {
        networkService
            .getGasUnitPrice()
            .withWeakCaptureOf(self)
            .tryMap { (walletManager, feeParams) -> AnyPublisher<AptosEstimatedGasPrice, Error> in
                let transactionInfo = try walletManager.transactionBuilder.buildToCalculateFee(
                    amount: amount,
                    destination: destination,
                    gasUnitPrice: feeParams.gasEstimate.uint64Value
                )
                
                return walletManager
                    .networkService
                    .calculateUsedGasPriceUnit(info: transactionInfo)
                    .eraseToAnyPublisher()
            }
            .tryMap { feeValue in
                throw WalletError.failedToGetFee
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
