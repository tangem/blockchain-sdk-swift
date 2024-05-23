//
//  HederaNetworkService.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 25.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class HederaNetworkService {
    var currentProviderIndex: Int

    private let consensusProvider: HederaConsensusNetworkProvider
    private let restProviders: [HederaRESTNetworkProvider]

    init(
        consensusProvider: HederaConsensusNetworkProvider,
        restProviders: [HederaRESTNetworkProvider]
    ) {
        self.consensusProvider = consensusProvider
        self.restProviders = restProviders
        currentProviderIndex = 0
    }

    func getAccountInfo(publicKey: Data) -> some Publisher<HederaAccountInfo, Error> {
        return providerPublisher { provider in
            return provider
                .getAccounts(publicKey: publicKey.hexString)
                .eraseToAnyPublisher()
        }
        .tryMap { accounts in
            // `MultiNetworkProvider` must not switch on `HederaError.accountDoesNotExist`,
            // therefore we are performing DTO->Domain mapping outside the `providerPublisher`
            switch accounts.accounts.count {
            case 0:
                throw HederaError.accountDoesNotExist
            case 1:
                let account = accounts.accounts[0]

                // Account ID is the only essential piece of information for a particular account,
                // account alias and account EVM address may not exist at all
                guard let accountId = account.account else {
                    throw HederaError.accountDoesNotExist
                }

                return HederaAccountInfo(accountId: accountId, alias: account.alias, evmAddress: account.evmAddress)
            default:
                throw HederaError.multipleAccountsFound
            }
        }
    }

    func getBalance(accountId: String) -> some Publisher<HederaAccountBalance, Error> {
        let hbarBalancePublisher = makeHbarBalancePublisher(accountId: accountId)

        let tokenBalancesPublisher = providerPublisher { provider in
            return provider
                .getTokens(accountId: accountId)
                .eraseToAnyPublisher()
        }

        return hbarBalancePublisher
            .zip(tokenBalancesPublisher)
            .map { hbarBalance, tokenBalances in
                let tokenBalances = tokenBalances.tokens.map { tokenBalance in
                    return HederaAccountBalance.TokenBalance(
                        contractAddress: tokenBalance.tokenId,
                        balance: tokenBalance.balance,
                        decimalCount: tokenBalance.decimals
                    )
                }

                return HederaAccountBalance(hbarBalance: hbarBalance, tokenBalances: tokenBalances)
            }
            .eraseToAnyPublisher()
    }

    func getExchangeRate() -> some Publisher<HederaExchangeRate, Error> {
        return providerPublisher { provider in
            return provider
                .getExchangeRates()
                .map { exchangeRate in
                    let currentRate = Constants.centsPerDollar
                    * Decimal(exchangeRate.currentRate.hbarEquivalent)
                    / Decimal(exchangeRate.currentRate.centEquivalent)

                    let nextRate = Constants.centsPerDollar
                    * Decimal(exchangeRate.nextRate.hbarEquivalent)
                    / Decimal(exchangeRate.nextRate.centEquivalent)

                    return HederaExchangeRate(currentHBARPerUSD: currentRate, nextHBARPerUSD: nextRate)
                }
                .eraseToAnyPublisher()
        }
    }

    func send(transaction: HederaTransactionBuilder.CompiledTransaction) -> some Publisher<TransactionSendResult, Error> {
        return consensusProvider
            .send(transaction: transaction)
            .map(TransactionSendResult.init(hash:))
    }

    /// Expects `transactionHash` in a format suitable for Hedera Consensus node (like `0.0.3573746@1714034073.123382080`).
    /// - Note: Hedera Mirror node uses a slightly different format of TX ids, so the conversion between
    /// Consensus and Mirror formats is performed using `HederaTransactionIdConverter`.
    func getTransactionInfo(transactionHash: String) -> some Publisher<HederaTransactionInfo, Error> {
        let fallbackTransactionInfoPublisher = makeFallbackTransactionInfoPublisher(transactionHash: transactionHash)
        let converter = HederaTransactionIdConverter()

        return Deferred {
            return Future { promise in
                let result = Result { try converter.convertFromConsensusToMirror(transactionHash) }
                promise(result)
            }
        }
        .withWeakCaptureOf(self)
        .flatMap { networkService, mirrorNodeTransactionHash in
            return networkService.providerPublisher { provider in
                return provider
                    .getTransactionInfo(transactionHash: mirrorNodeTransactionHash)
                    .eraseToAnyPublisher()
            }
            .map { ($0, mirrorNodeTransactionHash) }
        }
        .tryMap { transactionInfos, mirrorNodeTransactionHash in
            guard let transactionInfo = transactionInfos
                .transactions
                .first(where: { $0.transactionId == mirrorNodeTransactionHash })
            else {
                throw HederaError.transactionNotFound
            }

            return transactionInfo
        }
        .tryMap { transactionInfo in
            let consensusNodeTransactionHash = try converter.convertFromMirrorToConsensus(transactionInfo.transactionId)
            let isPending: Bool

            // API schema doesn't list all possible values for the `transactionInfo.result` field,
            // so raw string matching is used instead
            switch transactionInfo.result {
            case "OK":
                // Precheck validations (`Status.ok`) performed locally
                isPending = true
            default:
                // All other transaction statuses mean either success of failure
                isPending = false
            }

            return HederaTransactionInfo(isPending: isPending, transactionHash: consensusNodeTransactionHash)
        }
        .catch { _ in
            return fallbackTransactionInfoPublisher
        }
    }

    /// - Note: For Hbar tx status fetching, the Mirror Node acts as a primary node, and the Consensus Node is a backup one.
    private func makeFallbackTransactionInfoPublisher(transactionHash: String) -> some Publisher<HederaTransactionInfo, Error> {
        return consensusProvider
            .getTransactionInfo(transactionHash: transactionHash)
            .map { transactionInfo in
                let isPending: Bool

                switch transactionInfo.status {
                case .ok:
                    // Precheck validations (`Status.ok`) performed locally
                    isPending = true
                default:
                    // All other transaction statuses mean either success of failure
                    isPending = false
                }

                return HederaTransactionInfo(isPending: isPending, transactionHash: transactionInfo.hash)
            }
    }

    /// - Note: For Hbar balance fetching, the Mirror Node acts as a primary node, and the Consensus Node is a backup one.
    private func makeHbarBalancePublisher(accountId: String) -> some Publisher<Int, Error> {
        let primaryHbarBalancePublisher = providerPublisher { provider in
            return provider
                .getBalance(accountId: accountId)
                .eraseToAnyPublisher()
        }
        .tryMap { accountBalance in
            guard let balance = accountBalance.balances.first(where: { $0.account == accountId }) else {
                throw HederaError.accountBalanceNotFound
            }

            return balance.balance
        }

        let fallbackHbarBalancePublisher = consensusProvider
            .getBalance(accountId: accountId)

        return primaryHbarBalancePublisher
            .catch { _ in
                return fallbackHbarBalancePublisher
            }
    }
}

// MARK: - MultiNetworkProvider protocol conformance

extension HederaNetworkService: MultiNetworkProvider {
    var providers: [HederaRESTNetworkProvider] { restProviders }
}

// MARK: - Constants

private extension HederaNetworkService {
    enum Constants {
        static let centsPerDollar = Decimal(100)
        static let hederaNetworkId = "hedera"
    }
}
