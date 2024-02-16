//
//  HederaWalletManager.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 25.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk

final class HederaWalletManager: BaseManager {
    private let networkService: HederaNetworkService
    private let transactionBuilder: HederaTransactionBuilder
    private let dataStorage: BlockchainDataStorage
    private let accountCreator: AccountCreator

    private lazy var maskedPublicKey: String = {
        let length = 4
        let publicKey = wallet.publicKey.blockchainKey.hexString

        return publicKey
            .dropLast(length)
            .map { _ in "•" }
            .joined()
        + publicKey.suffix(length)
    }()

    init(
        wallet: Wallet,
        networkService: HederaNetworkService,
        transactionBuilder: HederaTransactionBuilder,
        accountCreator: AccountCreator,
        dataStorage: BlockchainDataStorage
    ) {
        self.networkService = networkService
        self.transactionBuilder = transactionBuilder
        self.accountCreator = accountCreator
        self.dataStorage = dataStorage
        super.init(wallet: wallet)
    }

    @available(*, unavailable)
    override init(wallet: Wallet) {
        fatalError("\(#function) has not been implemented")
    }

    // MARK: - Wallet update

    override func update(completion: @escaping (Result<Void, Error>) -> Void) {
        cancellable = getAccountId()
            .withWeakCaptureOf(self)
            .flatMap { walletManager, accountId in
                return Publishers.CombineLatest(
                    walletManager.makeBalancePublisher(accountId: accountId),
                    walletManager.makeTransactionsInfoPublisher()
                )
            }
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

    private func updateWalletAddress(accountId: String) {
        let address = PlainAddress(value: accountId, publicKey: wallet.publicKey, type: .default)
        wallet.set(address: address)
    }

    private func makeBalancePublisher(accountId: String) -> some Publisher<Amount, Error> {
        return networkService
            .getBalance(accountId: accountId)
            .withWeakCaptureOf(self)
            .map { walletManager, balance in
                return Amount(with: walletManager.wallet.blockchain, value: balance)
            }
    }

    private func makeTransactionsInfoPublisher() -> some Publisher<[HederaTransactionInfo], Error> {
        return wallet
            .pendingTransactions
            .publisher
            .setFailureType(to: Error.self)
            .withWeakCaptureOf(self)
            .flatMap { walletManager, pendingTransaction in
                return walletManager.networkService.getTransactionInfo(transactionHash: pendingTransaction.hash)
            }
            .collect()
    }

    // MARK: - Account ID fetching, caching and creation

    /// - Note: Has a side-effect: updates local model (`wallet.address`) if needed.
    private func getAccountId() -> AnyPublisher<String, Error> {
        if let accountId = wallet.address.nilIfEmpty {
            Log.debug("\(#fileID): Hedera account ID for public key \(maskedPublicKey) obtained from the Wallet")
            return .justWithError(output: accountId)
        }

        return getCachedAccountId()
            .withWeakCaptureOf(self)
            .handleEvents(
                receiveOutput: { walletManager, accountId in
                    walletManager.updateWalletAddress(accountId: accountId)
                }
            )
            .map(\.1)
            .eraseToAnyPublisher()
    }

    /// - Note: Has a side-effect: updates local cache (`dataStorage`) if needed.
    private func getCachedAccountId() -> AnyPublisher<String, Error> {
        let maskedPublicKey = maskedPublicKey
        let storageKey = Constants.storageKeyPrefix + wallet
            .publicKey
            .blockchainKey
            .getSha256()
            .hexString

        return .justWithError(output: storageKey)
            .withWeakCaptureOf(self)
            .asyncMap { walletManager, storageKey -> String? in
                await walletManager.dataStorage.get(key: storageKey)
            }
            .withWeakCaptureOf(self)
            .flatMap { walletManager, accountId -> AnyPublisher<String, Error> in
                if let accountId = accountId?.nilIfEmpty {
                    Log.debug("\(#fileID): Hedera account ID for public key \(maskedPublicKey) obtained from the data storage")
                    return .justWithError(output: accountId)
                }

                return walletManager
                    .getRemoteAccountId()
                    .withWeakCaptureOf(walletManager)
                    .asyncMap { walletManager, accountId in
                        await walletManager.dataStorage.store(key: storageKey, value: accountId)
                        return accountId
                    }
                    .eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    /// - Note: Has a side-effect: creates a new account on the Hedera network if needed.
    private func getRemoteAccountId() -> some Publisher<String, Error> {
        let maskedPublicKey = maskedPublicKey

        return networkService
            .getAccountInfo(publicKey: wallet.publicKey)
            .map(\.accountId)
            .handleEvents(
                receiveOutput: { _ in
                    Log.debug("\(#fileID): Hedera account ID for public key \(maskedPublicKey) obtained from the mirror node")
                },
                receiveFailure: { error in
                    Log.error(
                        """
                        \(#fileID): Failed to obtain Hedera account ID for public key \(maskedPublicKey) \
                        from the mirror node due to error: \(error.localizedDescription)
                        """
                    )
                }
            )
            .tryCatch { [weak self] error in
                guard let self else {
                    throw error
                }

                switch error {
                case HederaError.accountDoesNotExist:
                    return createAccount()
                default:
                    throw error
                }
            }
    }

    private func createAccount() -> some Publisher<String, Error> {
        let maskedPublicKey = maskedPublicKey

        return accountCreator
            .createAccount(blockchain: wallet.blockchain, publicKey: wallet.publicKey)
            .eraseToAnyPublisher()
            .map(\.accountId)
            .handleEvents(
                receiveOutput: { _ in
                    Log.debug("\(#fileID): Hedera account ID for public key \(maskedPublicKey) obtained by creating account")
                },
                receiveFailure: { error in
                    Log.error(
                        """
                        \(#fileID): Failed to obtain Hedera account ID for public key \(maskedPublicKey) \
                        by creating account due to error: \(error.localizedDescription)
                        """
                    )
                }
            )
            .mapError(WalletError.blockchainUnavailable(underlyingError:))
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
        static let storageKeyPrefix = "hedera_wallet_"
        /// https://docs.hedera.com/hedera/networks/mainnet/fees
        static let cryptoTransferServiceCostInUSD = Decimal(string: "0.0001", locale: locale)
        /// Hedera fees are low, allow 10% safety margin to allow usage of not precise fee estimate.
        static let maxFeeMultiplier = Decimal(string: "1.1", locale: locale)
        /// Locale for string literals parsing.
        static let locale = Locale(identifier: "en_US")
    }
}
