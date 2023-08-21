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
        public let contract: String?
        
        public init(address: String, page: Page, contract: String? = nil) {
            self.address = address
            self.page = page
            self.contract = contract
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
