//
//  Page.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 26.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public struct TransactionHistoryPage: Hashable {
    public let limit: Int
    public let type: TypePage
    
    // Use for indexed navigation state
    public let number: Int
    public let total: Int
    
    // Use for linked navigation state
    public let next: String?
    
    public var canFetchMore: Bool {
        switch type {
        case .index:
            return number < total
        case .linked:
            return next != nil
        case .empty:
            return true
        }
    }
    
    public var nextPage: TransactionHistoryPage? {
        switch type {
        case .index:
            return TransactionHistoryPage(limit: limit, type: .index, number: number + 1, total: total)
        case .linked:
            return TransactionHistoryPage(limit: limit, type: .linked, next: next)
        case .empty:
            return nil
        }
    }
    
    // MARK: - Init
    
    public init(limit: Int = 20, type: TypePage = .empty, number: Int = 0, total: Int = 0, next: String? = nil) {
        self.limit = limit
        self.type = type
        self.number = number
        self.total = total
        self.next = next
    }
}

extension TransactionHistoryPage {
    public enum TypePage: Hashable {
        case empty
        case index
        case linked
    }
}
