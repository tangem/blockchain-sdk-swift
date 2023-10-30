//
//  NEARWalletManager.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 13.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class NEARWalletManager: BaseManager {
    private let networkService: NEARNetworkService

    private let transactionBuilder: NEARTransactionBuilder

    /// Contains an actual NEAR protocol configuration, fetched once per app session.
    /// - Warning: Don't use directly, use `getProtocolConfig()` instance method to get the most recent protocol config.
    private let protocolConfigCache: NEARProtocolConfigCache

    init(
        wallet: Wallet,
        networkService: NEARNetworkService,
        transactionBuilder: NEARTransactionBuilder,
        protocolConfigCache: NEARProtocolConfigCache
    ) {
        self.networkService = networkService
        self.transactionBuilder = transactionBuilder
        self.protocolConfigCache = protocolConfigCache
        super.init(wallet: wallet)
    }

    @available(*, unavailable)
    override init(wallet: Wallet) {
        fatalError("\(#function) has not been implemented")
    }

    override func update(completion: @escaping (Result<Void, Error>) -> Void) {
        cancellable = Publishers.CombineLatest(
            getProtocolConfig().setFailureType(to: Error.self),
            networkService.getInfo(accountId: wallet.address)
        )
        .withWeakCaptureOf(self)
        .tryMap { walletManager, input in
            let (protocolConfig, accountInfo) = input
            switch accountInfo {
            case .notInitialized:
                throw walletManager.makeNoAccountError(using: protocolConfig)
            case .initialized(let account):
                return (account, protocolConfig)
            }
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
            receiveValue: { [weak self] account, protocolConfig in
                self?.updateWallet(account: account, protocolConfig: protocolConfig)
            }
        )
    }

    private func updateWallet(account: NEARAccountInfo.Account, protocolConfig: NEARProtocolConfig) {
        let decimalValue = wallet.blockchain.decimalValue
        let reserveValue = account.storageUsageInBytes * protocolConfig.storageAmountPerByte / decimalValue
        wallet.add(reserveValue: reserveValue)

        let coinValue = max(account.amount.value - reserveValue, .zero)
        wallet.add(coinValue: coinValue)
    }

    private func makeNoAccountError(using protocolConfig: NEARProtocolConfig) -> WalletError {
        let networkName = wallet.blockchain.displayName
        let decimalValue = wallet.blockchain.decimalValue
        let reserveValue = Constants.accountDefaultStorageUsageInBytes * protocolConfig.storageAmountPerByte / decimalValue
        let reserveValueString = reserveValue.decimalNumber.stringValue
        let currencySymbol = wallet.blockchain.currencySymbol
        let errorMessage = "no_account_generic".localized(networkName, reserveValueString, currencySymbol)

        return WalletError.noAccount(message: errorMessage)
    }

    /// - Note: Never fails; if a network request fails, the local fallback value will be used.
    private func getProtocolConfig() -> AnyPublisher<NEARProtocolConfig, Never> {
        return Deferred { [weak self, networkService] in
            if let protocolConfig = self?.protocolConfigCache.get() {
                return Just(protocolConfig)
                    .eraseToAnyPublisher()
            }

            return networkService
                .getProtocolConfig()
                .replaceError(with: NEARProtocolConfig.fallbackProtocolConfig)
                .handleEvents(receiveOutput: { self?.protocolConfigCache.set($0) })
                .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }

    private func calculateBasicCostsSum(
        config: NEARProtocolConfig,
        gasPriceForCurrentBlock: Decimal,
        gasPriceForNextBlock: Decimal,
        senderIsReceiver: Bool
    ) -> Decimal {
        if senderIsReceiver {
            return config.senderIsReceiver.cumulativeBasicSendCost * gasPriceForCurrentBlock
            + config.senderIsReceiver.cumulativeBasicExecutionCost * gasPriceForNextBlock
        }

        return config.senderIsNotReceiver.cumulativeBasicSendCost * gasPriceForCurrentBlock
        + config.senderIsNotReceiver.cumulativeBasicExecutionCost * gasPriceForNextBlock
    }

    /// Additional fees for transer action are used only if the receiver has an implicit accound ID,
    /// see https://nomicon.io/RuntimeSpec/Fees/ for details.
    private func calculateAdditionalCostsSum(
        config: NEARProtocolConfig,
        gasPriceForCurrentBlock: Decimal,
        gasPriceForNextBlock: Decimal,
        senderIsReceiver: Bool,
        destination: String
    ) -> Decimal {
        guard NEARAddressUtil.isImplicitAccount(accountId: destination) else {
            return .zero
        }

        if senderIsReceiver {
            return config.senderIsReceiver.cumulativeAdditionalSendCost * gasPriceForCurrentBlock
            + config.senderIsReceiver.cumulativeAdditionalExecutionCost * gasPriceForNextBlock
        }

        return config.senderIsNotReceiver.cumulativeAdditionalSendCost * gasPriceForCurrentBlock
        + config.senderIsNotReceiver.cumulativeAdditionalExecutionCost * gasPriceForNextBlock
    }
}

// MARK: - WalletManager protocol conformance

extension NEARWalletManager: WalletManager {
    var currentHost: String { networkService.host }

    var allowsFeeSelection: Bool { false }

    func getFee(
        amount: Amount,
        destination: String
    ) -> AnyPublisher<[Fee], Error> {
        return Publishers.CombineLatest(
            getProtocolConfig().setFailureType(to: Error.self),
            networkService.getGasPrice()
        )
        .withWeakCaptureOf(self)
        .map { walletManager, input in
            let (config, gasPrice) = input
            // The gas units on this next block (where the `execution` action takes place) could be multiplied
            // by a gas price that's up to 1% different, since gas price is recalculated on each block
            let approximateGasPriceForNextBlock = gasPrice * 1.01
            let source = walletManager.wallet.address
            let senderIsReceiver = source.lowercased() == destination.lowercased()

            let basicCostsSum = walletManager.calculateBasicCostsSum(
                config: config,
                gasPriceForCurrentBlock: gasPrice,
                gasPriceForNextBlock: approximateGasPriceForNextBlock,
                senderIsReceiver: senderIsReceiver
            )

            let additionalCostsSum = walletManager.calculateAdditionalCostsSum(
                config: config,
                gasPriceForCurrentBlock: gasPrice,
                gasPriceForNextBlock: approximateGasPriceForNextBlock,
                senderIsReceiver: senderIsReceiver,
                destination: destination
            )

            let blockchain = walletManager.wallet.blockchain
            let feeValue = (basicCostsSum + additionalCostsSum) / blockchain.decimalValue
            let amount = Amount(with: blockchain, value: feeValue)

            return [Fee(amount)]
        }
        .eraseToAnyPublisher()
    }

    func send(
        _ transaction: Transaction,
        signer: TransactionSigner
    ) -> AnyPublisher<TransactionSendResult, Swift.Error> {
        return networkService
            .getAccessKeyInfo(accountId: wallet.address, publicKey: wallet.publicKey)
            .tryMap { accessKeyInfo -> NEARAccessKeyInfo in
                guard accessKeyInfo.canBeUsedForTransfer else {
                    throw WalletError.failedToBuildTx
                }

                return accessKeyInfo
            }
            .withWeakCaptureOf(self)
            .map { walletManager, accessKeyInfo in
                return NEARTransactionParams(
                    publicKey: walletManager.wallet.publicKey,
                    currentNonce: accessKeyInfo.currentNonce,
                    recentBlockHash: accessKeyInfo.recentBlockHash
                )
            }
            .withWeakCaptureOf(self)
            .tryMap { walletManager, transactionParams in
                let transaction = transaction.then { $0.params = transactionParams }
                let hash = try walletManager.transactionBuilder.buildForSign(transaction: transaction)

                return (hash, transactionParams)
            }
            .flatMap { hash, transactionParams in
                let signaturePublisher = signer.sign(hash: hash, walletPublicKey: transactionParams.publicKey)
                let transactionParamsPublisher = Just(transactionParams).setFailureType(to: Error.self)

                return Publishers.Zip(signaturePublisher, transactionParamsPublisher)
            }
            .withWeakCaptureOf(self)
            .tryMap { walletManager, input in
                let (signature, transactionParams) = input
                let transaction = transaction.then { $0.params = transactionParams }

                return try walletManager.transactionBuilder.buildForSend(transaction: transaction, signature: signature)
            }
            .withWeakCaptureOf(self)
            .flatMap { walletManager, transaction in
                return walletManager.networkService.send(transaction: transaction)
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - Constants

private extension NEARWalletManager {
    enum Constants {
        /// For existing accounts this value can be fetched using the `view_account` RPC API endpoint.
        ///
        /// For newly created implicit accounts with a single access key (the default) we have to use this constant.
        /// See https://docs.near.org/integrator/accounts and
        /// https://pages.near.org/papers/economics-in-sharded-blockchain/#transaction-and-storage-fees for details.
        static let accountDefaultStorageUsageInBytes: Decimal = 182
    }
}
