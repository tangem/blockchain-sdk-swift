//
//  HederaConsensusNetworkProvider.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 03.02.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Hedera

/// Provider for Hedera Consensus Nodes (GRPC) https://docs.hedera.com/hedera/networks/mainnet/mainnet-nodes
final class HederaConsensusNetworkProvider {
    private let isTestnet: Bool
    private let configuration: NetworkProviderConfiguration

    private lazy var client: Client = {
        return isTestnet ? Client.forTestnet() : Client.forMainnet()
    }()

    private var callbackQueue: DispatchQueue { .main }

    init(
        isTestnet: Bool,
        configuration: NetworkProviderConfiguration
    ) {
        self.isTestnet = isTestnet
        self.configuration = configuration
    }

    func getBalance(accountId: String) -> some Publisher<Decimal, Error> {
        return Deferred {
            Future { promise in
                let result = Result { try AccountId.fromString(accountId) }
                promise(result)
            }
        }
        .withWeakCaptureOf(self)
        .asyncMap { networkProvider, accountId in
            return try await AccountBalanceQuery()
                .accountId(accountId)
                .execute(networkProvider.client)
        }
        .map(\.hbars.value)
        .receive(on: callbackQueue)
    }

    func send(transaction: HederaTransactionBuilder.CompiledTransaction) -> some Publisher<String, Error> {
        return Just(transaction)
            .setFailureType(to: Error.self)
            .asyncMap { try await $0.sendAndGetHash() }
            .receive(on: callbackQueue)
    }

    func getTransactionInfo(transactionHash: String) -> some Publisher<HederaNetworkResult.TransactionInfo, Error> {
        return Deferred {
            Future { promise in
                let result = Result { try TransactionId.fromString(transactionHash) }
                promise(result)
            }
        }
        .withWeakCaptureOf(self)
        .asyncMap { networkProvider, transactionId in
            let transactionReceipt = try await TransactionReceiptQuery()
                .transactionId(transactionId)
                .execute(networkProvider.client)

            return (transactionReceipt, transactionId)
        }
        .tryMap { transactionReceipt, transactionId in
            let transactionId = transactionReceipt.transactionId ?? transactionId

            return HederaNetworkResult.TransactionInfo(
                status: transactionReceipt.status,
                hash: transactionId.toString()
            )
        }
        .receive(on: callbackQueue)
    }
}
