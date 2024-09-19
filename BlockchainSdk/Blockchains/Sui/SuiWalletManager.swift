//
// SuiWalletManager.swift
// BlockchainSdk
//
// Created by Sergei Iakovlev on 28.08.2024
// Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class SuiWalletManager: BaseManager, WalletManager {
    let networkService: SuiNetworkService
    let transactionBuilder: SuiTransactionBuilder
    
    init(wallet: Wallet, networkService: SuiNetworkService, transactionBuilder: SuiTransactionBuilder) {
        self.networkService = networkService
        self.transactionBuilder = transactionBuilder
        super.init(wallet: wallet)
    }

    override func update(completion: @escaping (Result<Void, any Error>) -> Void) {
        cancellable = networkService.getBalance(address: wallet.address, coin: .sui, cursor: nil)
            .sink(receiveCompletion: { [weak self] completionSubscriptions in
                if case let .failure(error) = completionSubscriptions {
                    self?.wallet.clearAmounts()
                    completion(.failure(error))
                }
            }, receiveValue: { [weak self] coins in
                self?.updateWallet(coins: coins)
                completion(.success(()))
            })
    }
    
    func updateWallet(coins: [SuiGetCoins.Coin]) {
        let objects = coins.compactMap({
            SuiCoinObject.from($0)
        })
        
        let hashes = Set(coins.map({ $0.previousTransaction }))
        let localHashes = Set(wallet.pendingTransactions.map { $0.hash })
        
        if hashes.isSuperset(of: localHashes) {
            wallet.clearPendingTransaction()
        }
        
        self.transactionBuilder.update(coins: objects)
        
        let totalBalance = objects.reduce(into: Decimal(0)) { partialResult, coin in
            partialResult += coin.balance
        }
        
        let coinValue = totalBalance / wallet.blockchain.decimalValue
        wallet.add(coinValue: coinValue)
    }
}

extension SuiWalletManager: BlockchainDataProvider {
    var currentHost: String {
        networkService.host
    }
}

extension SuiWalletManager: TransactionFeeProvider {
    var allowsFeeSelection: Bool { false }
    
    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], any Error> {
        networkService.getReferenceGasPrice()
            .withWeakCaptureOf(self)
            .flatMap({ manager, referencedGasPrice -> AnyPublisher<SuiInspectTransaction, any Error> in
                guard let decimalGasPrice = Decimal(stringValue: referencedGasPrice) else {
                    return .anyFail(error: WalletError.failedToParseNetworkResponse())
                }
                
                return manager.estimatedFee(amount: amount, destination: destination, referenceGasPrice: decimalGasPrice)
            })
            .withWeakCaptureOf(self)
            .tryMap({ manager, inspectTransaction in
                guard let usedGasPrice = Decimal(stringValue: inspectTransaction.input.gasData.price),
                      let computationCost = Decimal(stringValue: inspectTransaction.effects.gasUsed.computationCost),
                      let storageCost = Decimal(stringValue: inspectTransaction.effects.gasUsed.storageCost),
                      let nonRefundableStorageFee = Decimal(stringValue: inspectTransaction.effects.gasUsed.nonRefundableStorageFee) else {
                    throw WalletError.failedToParseNetworkResponse()
                }
                
                let budget = ((computationCost + storageCost + nonRefundableStorageFee) / SUIUtils.SuiGasBudgetScaleUpConstant).rounded(scale: 1, roundingMode: .up) * SUIUtils.SuiGasBudgetScaleUpConstant
                
                let feeAmount = Amount(with: manager.wallet.blockchain, value: budget / manager.wallet.blockchain.decimalValue)
                
                let params = SuiFeeParameters(gasPrice: usedGasPrice, gasBudget: budget)
                return [Fee(feeAmount, parameters: params)]
                
            })
            .eraseToAnyPublisher()
    }
    
    private func estimatedFee(amount: Amount, destination: String, referenceGasPrice: Decimal) -> AnyPublisher<SuiInspectTransaction, any Error> {
        Result {
            try transactionBuilder.buildForInspect(amount: amount, destination: destination, referenceGasPrice: referenceGasPrice)
        }
        .publisher
        .withWeakCaptureOf(self)
        .flatMap { (manager, base64tx: String) -> AnyPublisher<SuiInspectTransaction, Error> in
            return manager.networkService.dryTransaction(transaction: base64tx)
        }
        .eraseToAnyPublisher()
    }
}

extension SuiWalletManager: TransactionSender {
    func send(_ transaction: Transaction, signer: any TransactionSigner) -> AnyPublisher<TransactionSendResult, SendTxError> {
        Result {
            try transactionBuilder.buildForSign(transaction: transaction)
        }
        .publisher
        .withWeakCaptureOf(self)
        .flatMap { (manager, dataHash: Data) -> AnyPublisher<SignatureInfo, Error> in
            signer.sign(hash: dataHash, walletPublicKey: manager.wallet.publicKey)
        }
        .withWeakCaptureOf(self)
        .tryMap { manager, signatureInfo -> (txBytes: String, signature: String) in
            let output = try manager.transactionBuilder.buildForSend(transaction: transaction, signature: signatureInfo.signature)
            return output
        }
        .withWeakCaptureOf(self)
        .flatMap { manager, builtTransaction -> AnyPublisher<SuiExecuteTransaction, Error> in
            return manager.networkService
                .sendTransaction(transaction: builtTransaction.txBytes, signature: builtTransaction.signature)
                .mapSendError(tx: builtTransaction.txBytes)
                .eraseToAnyPublisher()
        }
        .withWeakCaptureOf(self)
        .tryMap { manager, tx in
            let mapper = PendingTransactionRecordMapper()
            let record = mapper.mapToPendingTransactionRecord(transaction: transaction, hash: tx.digest)
            
            manager.wallet.addPendingTransaction(record)
            
            return TransactionSendResult(hash: tx.digest)
        }
        .eraseSendError()
        .eraseToAnyPublisher()
    }
}
