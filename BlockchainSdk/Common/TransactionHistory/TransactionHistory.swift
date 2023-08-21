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
        public let page: Page
        public let amountType: Amount.AmountType
        
        public init(address: String, page: Page, amountType: Amount.AmountType) {
            self.address = address
            self.page = page
            self.amountType = amountType
        }
    }
}

extension TransactionHistory {
    public struct Response: Hashable {
        public let totalPages: Int
        public let totalRecordsCount: Int
        public let page: Page
        public let records: [TransactionRecord]
    }
}
