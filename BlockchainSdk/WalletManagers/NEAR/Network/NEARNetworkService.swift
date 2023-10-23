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
                .tryMap { jsonRPCResult in
                    guard let gasPrice = Decimal(string: jsonRPCResult.result.gasPrice) else {
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
                .map { jsonRPCResult in
                    let result = jsonRPCResult.result
                    let actionCreationConfig = result.runtimeConfig.transactionCosts.actionCreationConfig.transferCost
                    let actionReceiptCreationConfig = result.runtimeConfig.transactionCosts.actionReceiptCreationConfig
                    let cumulativeExecutionCost = Decimal(actionCreationConfig.execution)
                    + Decimal(actionReceiptCreationConfig.execution)

                    return NEARProtocolConfig(
                        senderIsReceiver: .init(
                            cumulativeExecutionCost: cumulativeExecutionCost,
                            cumulativeSendCost: Decimal(actionCreationConfig.sendSir)
                            + Decimal(actionReceiptCreationConfig.sendSir)
                        ),
                        senderIsNotReceiver: .init(
                            cumulativeExecutionCost: cumulativeExecutionCost,
                            cumulativeSendCost: Decimal(actionCreationConfig.sendNotSir)
                            + Decimal(actionReceiptCreationConfig.sendNotSir)
                        )
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
                .tryMap { jsonRPCResult in
                    let result = jsonRPCResult.result

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
                .tryMap { jsonRPCResult in
                    let result = jsonRPCResult.result

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
                .map { jsonRPCResult in
                    return TransactionSendResult(hash: jsonRPCResult.result.transaction.hash)
                }
                .eraseToAnyPublisher()
        }
    }
}
