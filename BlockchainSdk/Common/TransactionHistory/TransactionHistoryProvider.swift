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
public protocol TransactionHistoryProvider {
    func loadTransactionHistory(address: String, page: Page) -> AnyPublisher<TransactionHistoryResponse, Error>
}

public struct TransactionHistoryResponse: Hashable {
    public let totalPages: Int
    public let totalRecordsCount: Int
    public let page: Page
    public let records: [TransactionRecord]
}
