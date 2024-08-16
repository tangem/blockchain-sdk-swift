//
//  TransactionHistoryProvider.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 25.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

@available(iOS 13.0, *)
public protocol TransactionHistoryProvider: CustomStringConvertible {
    var canFetchHistory: Bool { get }

    /// Please use `loadTransactionHistoryExcludingZeroTransactions(request:)` instead
    func loadTransactionHistory(request: TransactionHistory.Request) -> AnyPublisher<TransactionHistory.Response, Error>
    func reset()
}

public extension TransactionHistoryProvider {
    func loadTransactionHistoryExcludingZeroTransactions(
        request: TransactionHistory.Request
    ) -> AnyPublisher<TransactionHistory.Response, Error> {
        loadTransactionHistory(request: request)
            .map { response in
                guard case .token = request.amountType else {
                    return response
                }
                
                let records = response.records.filter { record in
                    switch record.destination {
                    case .single(let destination):
                        destination.amount != 0
                    case .multiple(let destinations):
                        destinations.contains { $0.amount != 0 }
                    }
                }
                return TransactionHistory.Response(records: records)
            }
            .eraseToAnyPublisher()
    }
}
