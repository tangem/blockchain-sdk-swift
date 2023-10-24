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

    /// Fallback values that are actual at the time of implementation (Q4 2023).
    private static var fallbackProtocolConfig: NEARProtocolConfig {
        NEARProtocolConfig(
           senderIsReceiver: .init(
               cumulativeExecutionCost: Decimal(115123062500) + Decimal(108059500000),
               cumulativeSendCost: Decimal(115123062500) + Decimal(108059500000)
           ),
           senderIsNotReceiver: .init(
               cumulativeExecutionCost: Decimal(115123062500) + Decimal(108059500000),
               cumulativeSendCost: Decimal(115123062500) + Decimal(108059500000)
           )
       )
    }

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
                .replaceError(with: Self.fallbackProtocolConfig)
                .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
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

            let costsSum: Decimal
            if senderIsReceiver {
                costsSum = config.senderIsReceiver.cumulativeSendCost * gasPrice
                + config.senderIsReceiver.cumulativeExecutionCost * approximateGasPriceForNextBlock
            } else {
                costsSum = config.senderIsNotReceiver.cumulativeSendCost * gasPrice
                + config.senderIsNotReceiver.cumulativeExecutionCost * approximateGasPriceForNextBlock
            }

            let blockchain = walletManager.wallet.blockchain
            let feeValue = costsSum / blockchain.decimalValue
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
