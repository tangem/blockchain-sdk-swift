//
//  AlgorandWalletManager.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 09.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class AlgorandWalletManager: BaseManager {
    
    // MARK: - Private Properties
    
    private let transactionBuilder: AlgorandTransactionBuilder
    private let networkService: AlgorandNetworkService
    
    // MARK: - Init
    
    init(wallet: Wallet, transactionBuilder: AlgorandTransactionBuilder, networkService: AlgorandNetworkService) throws {
        self.transactionBuilder = transactionBuilder
        self.networkService = networkService
        super.init(wallet: wallet)
    }
    
    // MARK: - Implementation
    
    override func update(completion: @escaping (Result<Void, Error>) -> Void) {
        let transactionStatusesPublisher = wallet
            .pendingTransactions
            .publisher
            .setFailureType(to: Error.self)
            .withWeakCaptureOf(self)
            .flatMap { walletManager, transaction in
                return walletManager.networkService.getPendingTransaction(transactionHash: transaction.hash)
            }
            .compactMap({$0})
            .collect()
        
        let accountInfoPublisher = networkService
            .getAccount(address: wallet.address)
        
        cancellable = Publishers.CombineLatest(accountInfoPublisher, transactionStatusesPublisher)
            .withWeakCaptureOf(self)
            .sink(
                receiveCompletion: { [weak self] result in
                    switch result {
                    case .failure(let error):
                        self?.wallet.clearAmounts()
                        completion(.failure(error))
                    case .finished:
                        completion(.success(()))
                    }
                },
                receiveValue: { walletManager, input in
                    let (accountInfo, transactionsInfos) = input
                    
                    walletManager.updatePendingTransactions(with: transactionsInfos)
                    walletManager.update(with: accountInfo, completion: completion)
                }
            )
    }
    
}

// MARK: - Private Implementation

private extension AlgorandWalletManager {
    func update(with accountModel: AlgorandAccountModel, completion: @escaping (Result<Void, Error>) -> Void) {
        wallet.add(coinValue: accountModel.coinValue)
        wallet.add(reserveValue: accountModel.reserveValue)
        
        guard let coinValue = wallet.amounts[.coin]?.value, coinValue >= accountModel.existentialDeposit else {
            let error = makeNoAccountError(using: accountModel)
            completion(.failure(error))
            return
        }
        
        completion(.success(()))
    }
    
    func updatePendingTransactions(with transactionInfo: [AlgorandTransactionInfo]) {
        let completedTransactionHashes = transactionInfo
            .filter { $0.status == .committed || $0.status == .removed }
            .map { $0.transactionHash }
            .toSet()
        
        wallet.removePendingTransaction(where: completedTransactionHashes.contains(_:))
    }
}

// MARK: - WalletManager protocol conformance

extension AlgorandWalletManager: WalletManager {
    var currentHost: String { networkService.host }

    var allowsFeeSelection: Bool { false }

    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], Error> {
        networkService
            .getEstimatedFee()
            .withWeakCaptureOf(self)
            .map { walletManager, params in
                let targetFee = max(params.fee, params.minFee)
                return [Fee(targetFee)]
            }
            .eraseToAnyPublisher()
    }

    func send(
        _ transaction: Transaction,
        signer: TransactionSigner
    ) -> AnyPublisher<TransactionSendResult, Error> {
        sendViaCompileTransaction(transaction, signer: signer)
    }
}

// MARK: - Private Implementation

extension AlgorandWalletManager {
    private func sendViaCompileTransaction(
        _ transaction: Transaction,
        signer: TransactionSigner
    ) -> AnyPublisher<TransactionSendResult, Error> {
        networkService
            .getTransactionParams()
            .withWeakCaptureOf(self)
            .tryMap { (walletManager, params) in
                let hashForSign = try walletManager.transactionBuilder.buildForSign(transaction: transaction, with: params)
                return (hashForSign, params)
            }
            .flatMap { (hashForSign, params) in
                let signaturePublisher = signer.sign(hash: hashForSign, walletPublicKey: self.wallet.publicKey)
                let transactionParamsPublisher = Just(params).setFailureType(to: Error.self)

                return Publishers.Zip(signaturePublisher, transactionParamsPublisher)
            }
            .withWeakCaptureOf(self)
            .tryMap { walletManager, input -> Data in
                let (signature, buildParams) = input
                
                let dataForSend = try walletManager.transactionBuilder.buildForSend(
                    transaction: transaction,
                    with: buildParams,
                    signature: signature
                )
                
                return dataForSend
            }
            .withWeakCaptureOf(self)
            .flatMap { walletManager, transactionData -> AnyPublisher<String, Error> in
                return walletManager.networkService.sendTransaction(data: transactionData)
            }
            .withWeakCaptureOf(self)
            .map { walletManager, txId in
                let mapper = PendingTransactionRecordMapper()
                let record = mapper.mapToPendingTransactionRecord(transaction: transaction, hash: txId)
                walletManager.wallet.addPendingTransaction(record)
                return TransactionSendResult(hash: txId)
            }
            .eraseToAnyPublisher()
    }
    
    private func makeNoAccountError(using accountModel: AlgorandAccountModel) -> WalletError {
        let networkName = wallet.blockchain.displayName
        let reserveValue = accountModel.reserveValue
        let reserveValueString = reserveValue.decimalNumber.stringValue
        let currencySymbol = wallet.blockchain.currencySymbol
        let errorMessage = "no_account_generic".localized([networkName, reserveValueString, currencySymbol])

        return WalletError.noAccount(message: errorMessage)
    }
}

/*
 Every account on Algorand must have a minimum balance of 100,000 microAlgos. If ever a transaction is sent that would result in a balance lower than the minimum, the transaction will fail. The minimum balance increases with each asset holding the account has (whether the asset was created or owned by the account) and with each application the account created or opted in. Destroying a created asset, opting out/closing out an owned asset, destroying a created app, or opting out an opted in app decreases accordingly the minimum balance.
 */
extension AlgorandWalletManager: MinimumBalanceRestrictable {
    var minimumBalance: Amount {
        let minimumBalanceAmountValue = (wallet.amounts[.reserve] ?? Amount(with: wallet.blockchain, value: 0)).value
        return Amount(with: wallet.blockchain, value: minimumBalanceAmountValue)
    }
}
