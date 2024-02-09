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

    func getAccountInfo(publicKey: Wallet.PublicKey) -> some Publisher<HederaAccountInfo, Error> {
        return providerPublisher { provider in
            return provider
                .getAccounts(publicKey: publicKey.blockchainKey.hexString)
                .tryMap { accounts in
                    let account = accounts.accounts.first

                    // Account ID is the only essential piece of information for a particular account,
                    // account alias and account EVM address may not exist at all
                    guard let accountId = account?.account else {
                        throw WalletError.noAccount(message: "")    // TODO: Andrey Fedorov - Add an appropriate message or throw a different error?
                    }
                    
                    return HederaAccountInfo(accountId: accountId, alias: account?.alias, evmAddress: account?.evmAddress)
                }
                .eraseToAnyPublisher()
        }
    }

    func createAccount(request: HederaCreateAccountRequest) -> some Publisher<HederaAccountInfo, Error> {
        // TODO: Andrey Fedorov - Add actual implementation (IOS-5888)
        return Fail(error: WalletError.empty)
    }

    func getBalance(accountId: String) -> some Publisher<Decimal, Error> {
        return consensusProvider.getBalance(accountId: accountId)
    }

    func getExchangeRate() -> some Publisher<HederaExchangeRate, Error> {
        // TODO: Andrey Fedorov - Add actual implementation (IOS-4561)
        return providerPublisher { provider in
            return provider
                .getExchangeRates()
                .tryMap { _ in throw WalletError.empty }
                .eraseToAnyPublisher()
        }
    }

    func send(transaction: HederaTransactionBuilder.CompiledTransaction) -> some Publisher<TransactionSendResult, Error> {
        return consensusProvider.send(transaction: transaction)
    }

    func getTransactionInfo(transactionHash: String) -> some Publisher<HederaTransactionInfo, Error> {
        return consensusProvider
            .getTransactionInfo(transactionHash: transactionHash)
            .map { transactionInfo in
                let isSuccessful: Bool

                switch transactionInfo.status {
                case .ok, .success:
                    isSuccessful = true
                default:
                    isSuccessful = false
                }

                return HederaTransactionInfo(isSuccessful: isSuccessful, hash: transactionInfo.hash)
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
