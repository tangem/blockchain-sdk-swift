//
//  AlgorandWalletManager.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 09.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

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
        cancellable = networkService
            .getAccount(address: wallet.address)
            .withWeakCaptureOf(self)
            .sink(
                receiveCompletion: { completionSubscription in
                    if case let .failure(error) = completionSubscription {
                        completion(.failure(error))
                    }
                },
                receiveValue: { walletManager, account in
                    walletManager.update(with: account, completion: completion)
                }
            )
    }
    
}

// MARK: - Private Implementation

private extension AlgorandWalletManager {
    func update(with accountModel: AlgorandResponse.Account, completion: @escaping (Result<Void, Error>) -> Void) {
        let blanaceValues = calculateCoinValueWithReserveDeposit(from: accountModel)
        
        wallet.add(coinValue: blanaceValues.coinValue)
        wallet.add(reserveValue: blanaceValues.reserveValue)
        
        guard accountModel.amount < accountModel.minBalance else {
            let error = makeNoAccountError(using: accountModel)
            completion(.failure(error))
            return
        }
        
        completion(.success(()))
    }
    
    private func calculateCoinValueWithReserveDeposit(from accountModel: AlgorandResponse.Account) -> (coinValue: Decimal, reserveValue: Decimal) {
        let changeBalanceValue = accountModel.amount > accountModel.minBalance ? accountModel.amount - accountModel.minBalance : 0
        
        let decimalBalance = Decimal(changeBalanceValue)
        let coinBalance = decimalBalance / wallet.blockchain.decimalValue
        
        let decimalReserveBalance = Decimal(accountModel.minBalance)
        let reserveCoinBalance = decimalReserveBalance / wallet.blockchain.decimalValue
        
        return (coinBalance, reserveCoinBalance)
    }
}

// MARK: - WalletManager protocol conformance

extension AlgorandWalletManager: WalletManager {
    var currentHost: String { networkService.host }

    var allowsFeeSelection: Bool { true }

    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], Error> {
        networkService
            .getTransactionParams()
            .withWeakCaptureOf(self)
            .map { walletManager, response in
                let sourceFee = Decimal(response.fee) / walletManager.wallet.blockchain.decimalValue
                let minFee = Decimal(response.minFee) / walletManager.wallet.blockchain.decimalValue
                
                let targetFee = sourceFee > minFee ? sourceFee : minFee
                
                return [Fee(.init(with: walletManager.wallet.blockchain, value: targetFee))]
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
            .map { walletManager, transactionInfoParams -> (AlgorandBuildParams) in
                let buildParams = AlgorandBuildParams(
                    genesisId: transactionInfoParams.genesisId,
                    genesisHash: transactionInfoParams.genesisHash,
                    firstRound: transactionInfoParams.lastRound,
                    lastRound: transactionInfoParams.lastRound + 1000,
                    nonce: (transaction.params as? AlgorandTransactionParams)?.nonce
                )
                
                return buildParams
            }
            .withWeakCaptureOf(self)
            .tryMap { walletManager, buildParams -> (hash: Data, params: AlgorandBuildParams) in
                let hashForSign = try walletManager.transactionBuilder.buildForSign(transaction: transaction, with: buildParams)
                return (hashForSign, buildParams)
            }
            .flatMap { (hashForSign, buildParams) in
                let signaturePublisher = signer.sign(hash: hashForSign, walletPublicKey: self.wallet.publicKey)
                let transactionParamsPublisher = Just(buildParams).setFailureType(to: Error.self)

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
            .flatMap { walletManager, transactionData -> AnyPublisher<AlgorandResponse.TransactionResult, Error> in
                return walletManager.networkService.sendTransaction(data: transactionData)
            }
            .withWeakCaptureOf(self)
            .map { walletManager, transactionResult in
                let mapper = PendingTransactionRecordMapper()
                let record = mapper.mapToPendingTransactionRecord(transaction: transaction, hash: transactionResult.txId)
                walletManager.wallet.addPendingTransaction(record)
                return TransactionSendResult(hash: transactionResult.txId)
            }
            .eraseToAnyPublisher()
    }
    
    private func makeNoAccountError(using accountModel: AlgorandResponse.Account) -> WalletError {
        let networkName = wallet.blockchain.displayName
        let decimalValue = wallet.blockchain.decimalValue
        let reserveValue = Decimal(accountModel.minBalance) / decimalValue
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
