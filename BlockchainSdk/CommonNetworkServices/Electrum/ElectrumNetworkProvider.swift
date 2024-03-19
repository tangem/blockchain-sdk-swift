//
//  ElectrumNetworkProvider.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 11.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine

public class ElectrumNetworkProvider: MultiNetworkProvider {
    let providers: [ElectrumWebSocketManager]
    var currentProviderIndex: Int = 0
    
    private let decimalValue: Decimal
    
    init(providers: [ElectrumWebSocketManager], decimalValue: Decimal) {
        self.providers = providers
        self.decimalValue = decimalValue
    }

    func getAddressInfo(identifier: ElectrumWebSocketManager.IdentifierType) -> AnyPublisher<ElectrumAddressInfo, Error> {
        providerPublisher { provider in
            Future.async {
                async let balance = provider.getBalance(identifier: identifier)
                let unspents = try await provider.getUnspents(identifier: identifier)
                let transactions = try await self.getTransactions(by: unspents.map { $0.txHash }, on: provider)
                
                return try await ElectrumAddressInfo(
                    balance: Decimal(balance.confirmed),
                    outputs: unspents.map { unspent in
                        ElectrumUTXO(
                            position: unspent.txPos,
                            hash: unspent.txHash,
                            value: unspent.value,
                            height: unspent.height
                        )
                    }
                )
            }
            .eraseToAnyPublisher()
        }
    }
    
    func estimateFee() -> AnyPublisher<Decimal, Error> {
        providerPublisher { provider in
            Future.async {
                let fee = try await provider.estimateFee(block: 10)
                return Decimal(fee)
            }
            .eraseToAnyPublisher()
        }
    }
    
    private func getTransactions(by hashes: [String], on provider: Provider) async throws -> [ElectrumDTO.Response.Transaction] {
        try await withThrowingTaskGroup(of: ElectrumDTO.Response.Transaction.self) { [weak self] group in
            guard let self else { return [] }
            
            var transactions = [ElectrumDTO.Response.Transaction]()
            transactions.reserveCapacity(hashes.count)

            for hash in hashes {
                group.addTask {
                    return try await self.provider.getTransaction(transactionHash: hash)
                }
            }

            for try await transaction in group {
                transactions.append(transaction)
            }

            return transactions
        }
    }
}
