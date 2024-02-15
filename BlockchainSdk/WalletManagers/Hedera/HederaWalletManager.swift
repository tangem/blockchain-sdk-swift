//
//  HederaWalletManager.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 25.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class HederaWalletManager: BaseManager {
    private let networkService: HederaNetworkService
    private let transactionBuilder: HederaTransactionBuilder

    init(
        wallet: Wallet,
        networkService: HederaNetworkService,
        transactionBuilder: HederaTransactionBuilder
    ) {
        self.networkService = networkService
        self.transactionBuilder = transactionBuilder
        super.init(wallet: wallet)
    }

    @available(*, unavailable)
    override init(wallet: Wallet) {
        fatalError("\(#function) has not been implemented")
    }

    override func update(completion: @escaping (Result<Void, Error>) -> Void) {
        let transactionsInfoPublisher = wallet
            .pendingTransactions
            .publisher
            .setFailureType(to: Error.self)
            .withWeakCaptureOf(self)
            .flatMap { walletManager, pendingTransaction in
                return walletManager.networkService.getTransactionInfo(transactionHash: pendingTransaction.hash)
            }
            .collect()

        let balancePublisher = networkService
            .getBalance(accountId: wallet.address)
            .withWeakCaptureOf(self)
            .map { walletManager, balance in
                return Amount(with: walletManager.wallet.blockchain, value: balance)
            }

        cancellable = Publishers.CombineLatest(balancePublisher, transactionsInfoPublisher)
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
                receiveValue: { [weak self] input in
                    let (accountBalance, transactionsInfo) = input
                    self?.updateWallet(accountBalance: accountBalance, transactionsInfo: transactionsInfo)
                }
            )
    }

    private func updateWallet(
        accountBalance: Amount,
        transactionsInfo: [HederaTransactionInfo]
    ) {
        let completedTransactionHashes = transactionsInfo
            .filter { !$0.isPending }
            .map { $0.transactionHash }

        wallet.removePendingTransaction(where: completedTransactionHashes.contains(_:))
        wallet.add(amount: accountBalance)
    }

    private func updateWalletWithPendingTransaction(_ transaction: Transaction, sendResult: TransactionSendResult) {
        let mapper = PendingTransactionRecordMapper()
        let pendingTransaction = mapper.mapToPendingTransactionRecord(transaction: transaction, hash: sendResult.hash)

        wallet.addPendingTransaction(pendingTransaction)
    }
}

// MARK: - WalletManager protocol conformance

extension HederaWalletManager: WalletManager {
    var currentHost: String { networkService.host }

    var allowsFeeSelection: Bool { false }

    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], Error> {
        return networkService
            .getExchangeRate()
            .withWeakCaptureOf(self)
            .tryMap { walletManager, exchangeRate in
                guard 
                    let cryptoTransferServiceCostInUSD = Constants.cryptoTransferServiceCostInUSD,
                    let maxFeeMultiplier = Constants.maxFeeMultiplier
                else {
                    throw WalletError.failedToGetFee
                }

                let feeValue = exchangeRate.nextHBARPerUSD * cryptoTransferServiceCostInUSD * maxFeeMultiplier
                let feeAmount = Amount(with: walletManager.wallet.blockchain, value: feeValue)
                let fee = Fee(feeAmount)

                return [fee]
            }
            .eraseToAnyPublisher()
    }

    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<TransactionSendResult, Error> {
        return Deferred { [weak self]  in
            return Future { (promise: Future<HederaTransactionBuilder.CompiledTransaction, Error>.Promise) in
                guard let self else {
                    return promise(.failure(WalletError.empty))
                }

                let compiledTransaction = Result { try self.transactionBuilder.buildForSign(transaction: transaction) }
                promise(compiledTransaction)
            }
        }
        .tryMap { compiledTransaction in
            let hashesToSign = try compiledTransaction.hashesToSign()
            return (hashesToSign, compiledTransaction)
        }
        .withWeakCaptureOf(self)
        .flatMap { walletManager, input in
            let (hashesToSign, compiledTransaction) = input
            return signer
                .sign(hashes: hashesToSign, walletPublicKey: walletManager.wallet.publicKey)
                .map { ($0, compiledTransaction) }
        }
        .withWeakCaptureOf(self)
        .tryMap { walletManager, input in
            let (signatures, compiledTransaction) = input
            return try walletManager
                .transactionBuilder
                .buildForSend(transaction: compiledTransaction, signatures: signatures)
        }
        .withWeakCaptureOf(self)
        .flatMap { walletManager, compiledTransaction in
            return walletManager
                .networkService
                .send(transaction: compiledTransaction)
        }
        .withWeakCaptureOf(self)
        .handleEvents(
            receiveOutput: { walletManager, sendResult in
                walletManager.updateWalletWithPendingTransaction(transaction, sendResult: sendResult)
            }
        )
        .map(\.1)
        .eraseToAnyPublisher()
    }
}

// MARK: - Constants

private extension HederaWalletManager {
    private enum Constants {
        /// https://docs.hedera.com/hedera/networks/mainnet/fees
        static let cryptoTransferServiceCostInUSD = Decimal(string: "0.0001", locale: locale)
        /// Hedera fees are low, allow 10% safety margin to allow usage of not precise fee estimate.
        static let maxFeeMultiplier = Decimal(string: "1.1", locale: locale)
        /// Locale for string literals parsing.
        static let locale = Locale(identifier: "en_US")
    }
}
