//
//  TransactionHistory.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 16.08.2023.
//

import Foundation

public enum TransactionHistory {}

extension TransactionHistory {
    public struct Request: Hashable {
        public let address: String
        public let amountType: Amount.AmountType
        public let page: TransactionHistoryPage
        
        public init(address: String, amountType: Amount.AmountType, page: TransactionHistoryPage) {
            self.address = address
            self.amountType = amountType
            self.page = page
        }
    }
}

extension TransactionHistory {
    public struct Response: Hashable {
        public let totalPages: Int?
        public let totalRecordsCount: Int?
        public let page: TransactionHistoryPage
        public let records: [TransactionRecord]
        
        public init(totalPages: Int? = nil, totalRecordsCount: Int? = nil, page: TransactionHistoryPage, records: [TransactionRecord]) {
            self.totalPages = totalPages
            self.totalRecordsCount = totalRecordsCount
            self.page = page
            self.records = records
        }
    }
}
