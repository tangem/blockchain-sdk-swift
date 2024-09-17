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
    public let networkService: SuiNetworkService
    public let transactionBuilder: SuiTransactionBuilder
    
    public init(wallet: Wallet, networkService: SuiNetworkService) {
        self.networkService = networkService
        self.transactionBuilder = SuiTransactionBuilder(publicKey: wallet.publicKey, decimals: wallet.blockchain.decimalValue)
        super.init(wallet: wallet)
    }

    override func update(completion: @escaping (Result<Void, any Error>) -> Void) {
        cancellable = networkService.getBalance(address: wallet.address, coin: .sui, cursor: nil)
            .sink(receiveCompletion: { [weak self] completionSubscriptions in
                if case let .failure(error) = completionSubscriptions {
                    self?.wallet.clearAmounts()
                    self?.wallet.clearPendingTransaction()
                    completion(.failure(error))
                }
            }, receiveValue: { [weak self] balances in
                guard let self else {
                    completion(.failure(WalletError.empty))
                    return
                }
                
                let coins = balances.compactMap({
                    SuiCoinObject.from($0)
                })
                
                self.transactionBuilder.update(coins: coins)
                
                let totalBalance = coins.reduce(into: Decimal(0)) { partialResult, coin in
                    partialResult += coin.balance
                }
                
                let coinValue = totalBalance / self.wallet.blockchain.decimalValue
                
                self.wallet.add(coinValue: coinValue)
                completion(.success(()))
            })
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
        return networkService.getReferenceGasPrice()
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
                
                let budget = ((computationCost + storageCost + nonRefundableStorageFee) / Sui.SuiGasBudgetScaleUpConstant).rounded(scale: 1, roundingMode: .up) * Sui.SuiGasBudgetScaleUpConstant
                
                let feeAmount = Amount(with: manager.wallet.blockchain, value: budget / manager.wallet.blockchain.decimalValue)
                
                let params = SuiFeeParameters(gasPrice: usedGasPrice, gasBudget: budget)
                return [Fee(feeAmount, parameters: params)]
                
            })
            .eraseToAnyPublisher()
    }
    
    private func estimatedFee(amount: Amount, destination: String, referenceGasPrice: Decimal) -> AnyPublisher<SuiInspectTransaction, any Error> {
        return Just(())
            .setFailureType(to: Error.self)
            .withWeakCaptureOf(self)
            .tryMap { manager, _ in
                return try manager.transactionBuilder.buildForInspect(amount: amount, destination: destination, referenceGasPrice: referenceGasPrice)
            }
            .withWeakCaptureOf(self)
            .flatMap { (manager, base64tx: String) -> AnyPublisher<SuiInspectTransaction, Error> in
                return manager.networkService.dryTransaction(transaction: base64tx)
            }
            .eraseToAnyPublisher()
    }
}

extension SuiWalletManager: TransactionSender {
    func send(_ transaction: Transaction, signer: any TransactionSigner) -> AnyPublisher<TransactionSendResult, SendTxError> {
        Just(())
            .receive(on: DispatchQueue.global())
            .withWeakCaptureOf(self)
            .tryMap({ manager, input in
                try manager.transactionBuilder.buildForSign(transaction: transaction)
            })
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
