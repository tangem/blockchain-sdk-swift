//
//  NEARNetworkService.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 13.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class NEARNetworkService: MultiNetworkProvider {
    let providers: [NEARNetworkProvider]
    var currentProviderIndex: Int = 0

    private let blockchain: Blockchain

    init(
        blockchain: Blockchain,
        providers: [NEARNetworkProvider]
    ) {
        self.blockchain = blockchain
        self.providers = providers
    }

    func getGasPrice() -> AnyPublisher<Decimal, Error> {
        return providerPublisher { provider in
            return provider
                .getGasPrice()
                .tryMap { result in
                    guard let gasPrice = Decimal(string: result.gasPrice) else {
                        throw WalletError.failedToParseNetworkResponse
                    }

                    return gasPrice
                }
                .eraseToAnyPublisher()
        }
    }

    func getProtocolConfig() -> AnyPublisher<NEARProtocolConfig, Error> {
        return providerPublisher { provider in
            return provider
                .getProtocolConfig()
                .map { result in
                    let transactionCosts = result.runtimeConfig.transactionCosts
                    let actionCreationConfig = transactionCosts.actionCreationConfig.transferCost
                    let createAccountCostConfig = transactionCosts.actionCreationConfig.createAccountCost
                    let addKeyCostConfig = transactionCosts.actionCreationConfig.addKeyCost.fullAccessCost
                    let actionReceiptCreationConfig = transactionCosts.actionReceiptCreationConfig

                    let cumulativeBasicExecutionCost = Decimal(actionCreationConfig.execution)
                    + Decimal(actionReceiptCreationConfig.execution)

                    let cumulativeAdditionalExecutionCost = Decimal(createAccountCostConfig.execution)
                    + Decimal(addKeyCostConfig.execution)

                    let senderIsReceiverCumulativeBasicSendCost = Decimal(actionCreationConfig.sendSir)
                    + Decimal(actionReceiptCreationConfig.sendSir)

                    let senderIsReceiverCumulativeAdditionalSendCost = Decimal(createAccountCostConfig.sendSir)
                    + Decimal(addKeyCostConfig.sendSir)

                    let senderIsNotReceiverCumulativeBasicSendCost = Decimal(actionCreationConfig.sendNotSir)
                    + Decimal(actionReceiptCreationConfig.sendNotSir)

                    let senderIsNotReceiverCumulativeAdditionalSendCost = Decimal(createAccountCostConfig.sendNotSir)
                    + Decimal(addKeyCostConfig.sendNotSir)

                    let storageAmountPerByte = Decimal(result.runtimeConfig.storageAmountPerByte)
                    ?? NEARProtocolConfig.fallbackProtocolConfig.storageAmountPerByte

                    return NEARProtocolConfig(
                        senderIsReceiver: .init(
                            cumulativeBasicSendCost: senderIsReceiverCumulativeBasicSendCost,
                            cumulativeBasicExecutionCost: cumulativeBasicExecutionCost,
                            cumulativeAdditionalSendCost: senderIsReceiverCumulativeAdditionalSendCost,
                            cumulativeAdditionalExecutionCost: cumulativeAdditionalExecutionCost
                        ),
                        senderIsNotReceiver: .init(
                            cumulativeBasicSendCost: senderIsNotReceiverCumulativeBasicSendCost,
                            cumulativeBasicExecutionCost: cumulativeBasicExecutionCost,
                            cumulativeAdditionalSendCost: senderIsNotReceiverCumulativeAdditionalSendCost,
                            cumulativeAdditionalExecutionCost: cumulativeAdditionalExecutionCost
                        ),
                        storageAmountPerByte: storageAmountPerByte
                    )
                }
                .eraseToAnyPublisher()
        }
    }

    func getInfo(accountId: String) -> AnyPublisher<NEARAccountInfo, Error> {
        let blockchain = self.blockchain

        return providerPublisher { provider in
            return provider
                .getInfo(accountId: accountId)
                .tryMap { result in
                    guard let rawAmount = Decimal(string: result.amount) else {
                        throw WalletError.failedToParseNetworkResponse
                    }

                    let value = rawAmount / blockchain.decimalValue
                    let amount = Amount(with: blockchain, value: value)

                    return NEARAccountInfo(
                        accountId: accountId,
                        amount: amount,
                        recentBlockHash: result.blockHash
                    )
                }
                .eraseToAnyPublisher()
        }
    }

    func getAccessKeyInfo(accountId: String, publicKey: Wallet.PublicKey) -> AnyPublisher<NEARAccessKeyInfo, Error> {
        let publicKeyPayload = "ed25519:" + publicKey.blockchainKey.base58EncodedString

        return providerPublisher { provider in
            return provider
                .getAccessKeyInfo(accountId: accountId, publicKey: publicKeyPayload)
                .map { result in
                    return NEARAccessKeyInfo(
                        currentNonce: result.nonce,
                        recentBlockHash: result.blockHash,
                        canBeUsedForTransfer: result.permission == .fullAccess
                    )
                }
                .eraseToAnyPublisher()
        }
    }

    func send(transaction: Data) -> AnyPublisher<TransactionSendResult, Error> {
        return providerPublisher { provider in
            return provider
                .sendTransactionAwait(transaction.base64EncodedString())
                .map { result in
                    return TransactionSendResult(hash: result.transactionOutcome.id)
                }
                .eraseToAnyPublisher()
        }
    }
}
