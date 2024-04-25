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
import struct Hedera.AccountId

final class HederaWalletManager: BaseManager {
    private let networkService: HederaNetworkService
    private let transactionBuilder: HederaTransactionBuilder
    private let dataStorage: BlockchainDataStorage
    private let accountCreator: AccountCreator

    /// HBARs per 1 USD
    private var tokenAssociationFeeExchangeRate: Decimal?
    private var associatedTokensContractAddresses: Set<String> = [] // TODO: Andrey Fedorov - Should be cached on disk using `dataStorage`

    // Public key as a masked string (only the last four characters are revealed), suitable for use in logs
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
                    walletManager.networkService.getBalance(accountId: accountId),
                    walletManager.makePendingTransactionsInfoPublisher()
                )
            }
            .withWeakCaptureOf(self)
            .flatMap { walletManager, input in
                let (accountBalance, transactionsInfo) = input
                let alreadyAssociatedTokens = accountBalance.associatedTokensContractAddresses

                return walletManager
                    .makeTokenAssociationFeeExchangeRatePublisher(alreadyAssociatedTokens: alreadyAssociatedTokens)
                    .map { exchangeRate in
                        return (accountBalance, transactionsInfo, exchangeRate)
                    }
            }
            .sink(
                receiveCompletion: { [weak self] result in
                    switch result {
                    case .failure(let error):
                        // We intentionally don't want to clear current token associations on failure
                        self?.wallet.clearAmounts()
                        completion(.failure(error))
                    case .finished:
                        completion(.success(()))
                    }
                },
                receiveValue: { [weak self] accountBalance, transactionsInfo, exchangeRate in
                    self?.updateWallet(accountBalance: accountBalance, transactionsInfo: transactionsInfo)
                    self?.updateWalletTokens(accountBalance: accountBalance, exchangeRate: exchangeRate)
                }
            )
    }

    private func updateWallet(
        accountBalance: HederaAccountBalance,
        transactionsInfo: [HederaTransactionInfo]
    ) {
        let completedTransactionHashes = transactionsInfo
            .filter { !$0.isPending }
            .map { $0.transactionHash }

        wallet.removePendingTransaction(where: completedTransactionHashes.contains(_:))
        wallet.add(coinValue: accountBalance.hbarBalance)
    }

    private func updateWalletTokens(accountBalance: HederaAccountBalance, exchangeRate: HederaExchangeRate?) {
        tokenAssociationFeeExchangeRate = exchangeRate?.nextHBARPerUSD
        associatedTokensContractAddresses = accountBalance.associatedTokensContractAddresses

        // Using HTS tokens balances from a remote list of tokens for tokens in a local list
        cardTokens
            .map { token in
                guard
                    let balance = accountBalance.tokenBalances.first(where: { token.contractAddress == $0.contractAddress })
                else {
                    return Amount(with: token, value: .zero)
                }

                return Amount(with: token, value: balance.balance)
            }
            .forEach { wallet.add(amount: $0) }
    }

    private func updateWalletWithPendingTransferTransaction(_ transaction: Transaction, sendResult: TransactionSendResult) {
        let mapper = HederaPendingTransactionRecordMapper(blockchain: wallet.blockchain)
        let pendingTransaction = mapper.mapToTransferPendingTransactionRecord(
            transaction: transaction,
            hash: sendResult.hash
        )
        wallet.addPendingTransaction(pendingTransaction)
    }

    private func updateWalletWithPendingTokenAssociationTransaction(_ token: Token, sendResult: TransactionSendResult) {
        let mapper = HederaPendingTransactionRecordMapper(blockchain: wallet.blockchain)
        let pendingTransaction = mapper.mapToTokenAssociationPendingTransactionRecord(
            token: token,
            hash: sendResult.hash,
            accountId: wallet.address
        )
        wallet.addPendingTransaction(pendingTransaction)
    }

    private func updateWalletAddress(accountId: String) {
        let address = PlainAddress(value: accountId, publicKey: wallet.publicKey, type: .default)
        wallet.set(address: address)
    }

    private func makeTokenAssociationFeeExchangeRatePublisher(
        alreadyAssociatedTokens: Set<String>
    ) -> some Publisher<HederaExchangeRate?, Error> {
        if cardTokens.allSatisfy({ alreadyAssociatedTokens.contains($0.contractAddress) }) {
            // All added tokens (from `cardTokens`) are already associated with the current account;
            // therefore there is no point in requesting an exchange rate to calculate the token association fee
            //
            // Performing an early exit
            return Just(nil)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }

        return networkService
            .getExchangeRate()
            .map { $0 as HederaExchangeRate? }  // Combine can't implicitly bridge `Publisher<T, Error>` to `Publisher<T?, Error`
            .eraseToAnyPublisher()
    }

    private func makePendingTransactionsInfoPublisher() -> some Publisher<[HederaTransactionInfo], Error> {
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

    /// Used to query the status of the `receiving` (`destination`) account.
    private func doesAccountExist(destination: String) -> some Publisher<Bool, Error> {
        return Deferred {
            return Future { promise in
                let result = Result { try Hedera.AccountId(parsing: destination) }
                promise(result)
            }
        }
        .withWeakCaptureOf(self)
        .flatMap { walletManager, accountId in
            // Accounts with an account ID and/or EVM address are considered existing accounts
            let accountHasValidAccountIdOrEVMAddress = accountId.num != 0 || accountId.evmAddress != nil

            if accountHasValidAccountIdOrEVMAddress {
                return Just(true)
                    .eraseToAnyPublisher()
            }

            guard let alias = accountId.alias else {
                // Perhaps an unreachable case: account doesn't have an account ID, EVM address, or account alias
                return Just(false)
                    .eraseToAnyPublisher()
            }

            // Any error returned from the API is treated as a non-existent account, just in case
            return walletManager
                .networkService
                .getAccountInfo(publicKey: alias.toBytesRaw())  // ECDSA key must be in a compressed form
                .map { _ in true }
                .replaceError(with: false)
                .eraseToAnyPublisher()
        }
    }

    /// - Note: Has a side-effect: updates local model (`wallet.address`) if needed.
    private func getAccountId() -> AnyPublisher<String, Error> {
        let maskedPublicKey = maskedPublicKey

        if let accountId = wallet.address.nilIfEmpty {
            Log.debug("\(#fileID): Hedera account ID for public key \(maskedPublicKey) obtained from the Wallet")
            return .justWithError(output: accountId)
        }

        return getCachedAccountId()
            .withWeakCaptureOf(self)
            .handleEvents(
                receiveOutput: { walletManager, accountId in
                    walletManager.updateWalletAddress(accountId: accountId)
                    Log.debug("\(#fileID): Hedera account ID for public key \(maskedPublicKey) saved to the Wallet")
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
                        Log.debug("\(#fileID): Hedera account ID for public key \(maskedPublicKey) saved to the data storage")
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
            .getAccountInfo(publicKey: wallet.publicKey.blockchainKey)
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
            .tryMap { createdAccount in
                guard let hederaCreatedAccount = createdAccount as? HederaCreatedAccount else {
                    assertionFailure("Expected entity of type '\(HederaCreatedAccount.self)', got '\(type(of: createdAccount))' instead")
                    throw HederaError.failedToCreateAccount
                }

                return hederaCreatedAccount.accountId
            }
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

    // MARK: - Transaction dependencies and building

    private func getFee(amount: Amount, doesAccountExistPublisher: some Publisher<Bool, Error>) -> AnyPublisher<[Fee], Error> {
        let transferFeeBase: Decimal
        switch amount.type {
        case .coin:
            transferFeeBase = Constants.cryptoTransferServiceCostInUSD
        case .token:
            transferFeeBase = Constants.tokenTransferServiceCostInUSD
        case .reserve:
            return .anyFail(error: WalletError.failedToGetFee)
        }

        return Publishers.CombineLatest(
            networkService.getExchangeRate(),
            doesAccountExistPublisher
        )
        .withWeakCaptureOf(self)
        .tryMap { walletManager, input in
            let (exchangeRate, doesAccountExist) = input
            let feeBase = doesAccountExist ? transferFeeBase : Constants.cryptoCreateServiceCostInUSD
            let feeValue = exchangeRate.nextHBARPerUSD * feeBase * Constants.maxFeeMultiplier
            let feeAmount = Amount(with: walletManager.wallet.blockchain, value: feeValue)
            let fee = Fee(feeAmount)

            return [fee]
        }
        .eraseToAnyPublisher()
    }

    private static func makeTransactionValidStartDate() -> UnixTimestamp? {
        // Subtracting `validStartDateDiff` from the `Date.now` to make sure that the tx valid start date has already passed
        // The logic is the same as in the `Hedera.TransactionId.generateFrom(_:)` factory method
        let validStartDateDiff = Int.random(in: 5_000_000_000..<8_000_000_000)
        let validStartDate = Calendar.current.date(byAdding: .nanosecond, value: -validStartDateDiff, to: Date())

        return validStartDate.flatMap(UnixTimestamp.init(date:))
    }

    private func sendCompiledTransaction(
        signedUsing signer: TransactionSigner,
        transactionFactory: @escaping (_ validStartDate: UnixTimestamp) throws -> HederaTransactionBuilder.CompiledTransaction
    ) -> AnyPublisher<TransactionSendResult, Error> {
        return Deferred {
            return Future { (promise: Future<HederaTransactionBuilder.CompiledTransaction, Error>.Promise) in
                guard let validStartDate = Self.makeTransactionValidStartDate() else {
                    return promise(.failure(WalletError.failedToBuildTx))
                }

                let compiledTransaction = Result { try transactionFactory(validStartDate) }
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
        .eraseToAnyPublisher()
    }
}

// MARK: - WalletManager protocol conformance

extension HederaWalletManager: WalletManager {
    var currentHost: String { networkService.host }

    var allowsFeeSelection: Bool { false }

    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], Error> {
        let doesAccountExistPublisher = doesAccountExist(destination: destination)

        return getFee(amount: amount, doesAccountExistPublisher: doesAccountExistPublisher)
    }

    func estimatedFee(amount: Amount) -> AnyPublisher<[Fee], Error> {
        // For a rough fee estimation (calculated in this method), all destinations are considered non-existent just in case
        let doesAccountExistPublisher = Just(false).setFailureType(to: Error.self)

        return getFee(amount: amount, doesAccountExistPublisher: doesAccountExistPublisher)
    }

    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<TransactionSendResult, Error> {
        return sendCompiledTransaction(signedUsing: signer) { [weak self] validStartDate in
            guard let self else {
                throw WalletError.empty
            }

            return try self.transactionBuilder.buildTransferTransactionForSign(
                transaction: transaction,
                validStartDate: validStartDate,
                nodeAccountIds: nil
            )
        }
        .withWeakCaptureOf(self)
        .handleEvents(receiveOutput: { walletManager, sendResult in
            walletManager.updateWalletWithPendingTransferTransaction(transaction, sendResult: sendResult)
        })
        .map(\.1)
        .eraseToAnyPublisher()
    }
}

// MARK: - AssetRequirementsManager protocol conformance

extension HederaWalletManager: AssetRequirementsManager {
    func hasRequirements(for asset: Asset) -> Bool {
        switch asset {
        case .coin, .reserve:
            return false
        case .token(let token):
            return !associatedTokensContractAddresses.contains(token.contractAddress)
        }
    }

    func requirementsCondition(for asset: Asset) -> AssetRequirementsCondition? {
        guard hasRequirements(for: asset) else {
            return nil
        }

        switch asset {
        case .coin, .reserve:
            return nil
        case .token:
            guard let tokenAssociationFeeExchangeRate else {
                return .paidTransaction
            }

            let feeValue = tokenAssociationFeeExchangeRate * Constants.tokenAssociateServiceCostInUSD
            let feeAmount = Amount.init(with: wallet.blockchain, value: feeValue)

            return .paidTransactionWithFee(feeAmount: feeAmount)
        }
    }

    func fulfillRequirements(for asset: Asset, signer: any TransactionSigner) -> AnyPublisher<Void, Error> {
        guard hasRequirements(for: asset) else {
            return .justWithError(output: ())
        }

        switch asset {
        case .coin, .reserve:
            return .justWithError(output: ())
        case .token(let token):
            return sendCompiledTransaction(signedUsing: signer) { [weak self] validStartDate in
                guard let self else {
                    throw WalletError.empty
                }

                return try self.transactionBuilder.buildTokenAssociationForSign(
                    tokenAssociation: .init(accountId: self.wallet.address, contractAddress: token.contractAddress),
                    validStartDate: validStartDate,
                    nodeAccountIds: nil
                )
            }
            .withWeakCaptureOf(self)
            .handleEvents(receiveOutput: { walletManager, sendResult in
                walletManager.updateWalletWithPendingTokenAssociationTransaction(token, sendResult: sendResult)
            })
            .mapToVoid()
            .eraseToAnyPublisher()
        }
    }
}

// MARK: - Constants

private extension HederaWalletManager {
    private enum Constants {
        static let storageKeyPrefix = "hedera_wallet_"
        /// https://docs.hedera.com/hedera/networks/mainnet/fees
        static let cryptoTransferServiceCostInUSD = Decimal(stringValue: "0.0001")!
        static let tokenTransferServiceCostInUSD = Decimal(stringValue: "0.001")!
        static let cryptoCreateServiceCostInUSD = Decimal(stringValue: "0.05")!
        static let tokenAssociateServiceCostInUSD = Decimal(stringValue: "0.05")!
        /// Hedera fees are low, allow 10% safety margin to allow usage of not precise fee estimate.
        static let maxFeeMultiplier = Decimal(stringValue: "1.1")!
    }
}

// MARK: - Convenience extensions

private extension HederaAccountBalance {
    var associatedTokensContractAddresses: Set<String> {
        return tokenBalances
            .map(\.contractAddress)
            .toSet()
    }
}
