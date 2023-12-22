//
//  VeChainWalletManager.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 18.12.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class VeChainWalletManager: BaseManager {
    private let networkService: VeChainNetworkService
    private let transactionBuilder: VeChainTransactionBuilder

    init(
        wallet: Wallet,
        energyToken: Token,
        networkService: VeChainNetworkService,
        transactionBuilder: VeChainTransactionBuilder
    ) {
        self.networkService = networkService
        self.transactionBuilder = transactionBuilder
        super.init(wallet: wallet)
        cardTokens = [energyToken]
    }

    @available(*, unavailable)
    override init(wallet: Wallet) {
        fatalError("\(#function) has not been implemented")
    }

    override func update(completion: @escaping (Result<Void, Error>) -> Void) {
        cancellable = networkService
            .getAccountInfo(address: wallet.address)
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
                receiveValue: { walletManager, accountInfo in
                    walletManager.updateWallet(accountInfo: accountInfo)
                }
            )
    }

    private func updateWallet(
        accountInfo: VeChainAccountInfo
    ) {
        let amounts = accountInfo.tokenAmounts + [accountInfo.amount]
        amounts.forEach { wallet.add(amount: $0) }
    }
}

// MARK: - WalletManager protocol conformance

extension VeChainWalletManager: WalletManager {
    var currentHost: String { networkService.host }

    var allowsFeeSelection: Bool { false }

    func getFee(
        amount: Amount,
        destination: String
    ) -> AnyPublisher<[Fee], Error> {
        // TODO: Andrey Fedorov - Add actual implementation (IOS-5238)
        return .emptyFail
    }

    func send(
        _ transaction: Transaction,
        signer: TransactionSigner
    ) -> AnyPublisher<TransactionSendResult, Error> {
        return networkService
            .getLatestBlockInfo()
            .withWeakCaptureOf(self)
            .map { walletManager, lastBlockInfo in
                // Using a random nonce value for a new transaction is totally fine,
                // see https://docs.vechain.org/core-concepts/transactions/transaction-model for details
                return VeChainTransactionParams(
                    publicKey: walletManager.wallet.publicKey,
                    lastBlockInfo: lastBlockInfo,
                    nonce: .random(in: 1 ..< UInt.max)
                )
            }
            .withWeakCaptureOf(self)
            .tryMap { walletManager, transactionParams -> (Data, VeChainTransactionParams) in
                let transaction = transaction.then { $0.params = transactionParams }
                let hash = try walletManager.transactionBuilder.buildForSign(transaction: transaction)

                return (hash, transactionParams)
            }
            .flatMap { hash, transactionParams in
                return signer
                    .sign(hash: hash, walletPublicKey: transactionParams.publicKey)
                    .map { ($0, hash, transactionParams) }
            }
            .withWeakCaptureOf(self)
            .tryMap { walletManager, input in
                let (signature, hash, transactionParams) = input
                let transaction = transaction.then { $0.params = transactionParams }

                return try walletManager.transactionBuilder.buildForSend(
                    transaction: transaction,
                    hash: hash,
                    signature: signature
                )
            }
            .withWeakCaptureOf(self)
            .flatMap { walletManager, transaction in
                return walletManager.networkService.send(transaction: transaction)
            }
            .eraseToAnyPublisher()
    }
}
