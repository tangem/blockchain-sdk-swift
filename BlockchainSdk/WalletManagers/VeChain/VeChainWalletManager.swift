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
    
    private var energyToken: Token {
        return cardTokens.first(where: \.isEnergyToken) ?? Constants.energyToken
    }

    init(
        wallet: Wallet,
        networkService: VeChainNetworkService,
        transactionBuilder: VeChainTransactionBuilder
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

    override func addToken(_ token: Token) {
        let tokenAmount = wallet.amounts[.token(value: Constants.energyToken)]

        super.addToken(token)

        // When the real "VeThor" energy token is being added to the token list,
        // we're trying to migrate the balance from the fallback energy token to the real one
        if token.isEnergyToken, let energyTokenAmount = tokenAmount {
            wallet.remove(token: Constants.energyToken)
            wallet.add(tokenValue: energyTokenAmount.value, for: token)
        }
    }

    override func removeToken(_ token: Token) {
        let tokenAmount = wallet.amounts[.token(value: token)]

        super.removeToken(token)

        // When the real "VeThor" energy token is being deleted from the token list,
        // we're trying to migrate the balance from the real energy token to the fallback one
        if token.isEnergyToken, let energyTokenAmount = tokenAmount {
            wallet.remove(token: token)
            wallet.add(tokenValue: energyTokenAmount.value, for: Constants.energyToken)
        }
    }

    private func updateWallet(accountInfo: VeChainAccountInfo) {
        let amounts = [
            accountInfo.amount,
            accountInfo.energyAmount(with: energyToken),
        ]
        amounts.forEach { wallet.add(amount: $0) }
    }

    private func makeTransactionForFeeCalculation(amount: Amount, destination: String) -> Transaction {
        // Doesn't affect fee calculation
        let dummyBlockInfo = VeChainBlockInfo(
            blockId: "",
            blockRef: 1,
            blockNumber: 1
        )
        // Doesn't affect fee calculation
        let dummyParams = VeChainTransactionParams(
            publicKey: wallet.publicKey,
            lastBlockInfo: dummyBlockInfo,
            nonce: 1
        )
        // Doesn't affect fee calculation
        let dummyFee = Fee(.zeroCoin(for: wallet.blockchain))

        return Transaction(
            amount: amount,
            fee: dummyFee,
            sourceAddress: wallet.address,
            destinationAddress: destination,
            changeAddress: wallet.address,
            params: dummyParams
        )
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
        return Deferred { [weak self] in
            Future { promise in
                guard let self = self else {
                    promise(.failure(WalletError.empty))
                    return
                }

                let transaction = self.makeTransactionForFeeCalculation(amount: amount, destination: destination)
                promise(.success(transaction))
            }
        }
        .withWeakCaptureOf(self)
        .tryMap { walletManager, transaction in
            return try walletManager.transactionBuilder.buildInputForFeeCalculation(transaction: transaction)
        }
        .withWeakCaptureOf(self)
        .map { walletManager, input in
            let feeCalculator = VeChainFeeCalculator(blockchain: walletManager.wallet.blockchain)
            let fee = feeCalculator.fee(for: input, amountType: .token(value: walletManager.energyToken))

            return [fee]
        }
        .eraseToAnyPublisher()
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

// MARK: - Constants

private extension VeChainWalletManager {
    enum Constants {
        /// A local energy token ("VeThor"), used as a fallback for fee calculation when
        /// the user doesn't have a real "VeThor" token added to the token list.
        ///
        /// See https://docs.vechain.org/introduction-to-vechain/dual-token-economic-model/vethor-vtho for details and specs.
        static let energyToken = Token(
            name: "VeThor",
            symbol: "VTHO",
            contractAddress: "0x0000000000000000000000000000456e65726779",
            decimalCount: 18
        )
    }
}

// MARK: - Convenience extensions

private extension Token {
    var isEnergyToken: Bool {
        let energyTokenContractAddress = VeChainWalletManager.Constants.energyToken.contractAddress

        return contractAddress.caseInsensitiveCompare(energyTokenContractAddress) == .orderedSame
    }
}
