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
    /// Current actual values, fetched once per app session.
    private static var cachedProtocolConfig: NEARProtocolConfig?

    private let networkService: NEARNetworkService
    private let transactionBuilder: NEARTransactionBuilder

    init(
        wallet: Wallet,
        networkService: NEARNetworkService,
        transactionBuilder: NEARTransactionBuilder
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
        cancellable = networkService
            .getInfo(accountId: wallet.address)
            .sink(
                receiveCompletion: { result in
                    switch result {
                    case .failure(let error):
                        self.wallet.clearAmounts()
                        completion(.failure(error))
                    case .finished:
                        completion(.success(()))
                    }
                },
                receiveValue: { [weak self] value in
                    self?.wallet.add(amount: value.amount)
                }
            )
    }

    private func getProtocolConfig() -> AnyPublisher<NEARProtocolConfig, Never> {
        return Deferred { [networkService] in
            if let protocolConfig = Self.cachedProtocolConfig {
                return Just(protocolConfig)
                    .eraseToAnyPublisher()
            }

            return networkService
                .getProtocolConfig()
                .handleEvents(receiveOutput: { Self.cachedProtocolConfig = $0 })
                .replaceError(with: Constants.fallbackProtocolConfig)
                .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }

    /// See https://nomicon.io/DataStructures/Account#account-id-rules for infomation about implicit/named account IDs.
    private func isImplicitAccount(accountId: String) -> Bool {
        guard accountId.count == Constants.implicitAccountAddressLength else {
            return false
        }

        // `CharacterSet.alphanumerics` contains other non-ASCII characters, like diacritics, arabic, etc -
        // so it can't be used to match the regex `[a-zA-Z\d]+`
        return accountId.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber) }
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
        guard isImplicitAccount(accountId: destination) else {
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
        /// Fallback values that are actual at the time of implementation (Q4 2023).
        static var fallbackProtocolConfig: NEARProtocolConfig {
            NEARProtocolConfig(
                senderIsReceiver: .init(
                    cumulativeBasicSendCost: Decimal(115123062500) + Decimal(108059500000),
                    cumulativeBasicExecutionCost: Decimal(115123062500) + Decimal(108059500000),
                    cumulativeAdditionalSendCost: Decimal(3850000000000) + Decimal(101765125000),
                    cumulativeAdditionalExecutionCost: Decimal(3850000000000) + Decimal(101765125000)
                ),
                senderIsNotReceiver: .init(
                    cumulativeBasicSendCost: Decimal(115123062500) + Decimal(108059500000),
                    cumulativeBasicExecutionCost: Decimal(115123062500) + Decimal(108059500000),
                    cumulativeAdditionalSendCost: Decimal(3850000000000) + Decimal(101765125000),
                    cumulativeAdditionalExecutionCost: Decimal(3850000000000) + Decimal(101765125000)
                )
            )
        }

        static let implicitAccountAddressLength = 64
    }
}
