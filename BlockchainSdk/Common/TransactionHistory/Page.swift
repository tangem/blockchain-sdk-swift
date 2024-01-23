//
//  Page.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 26.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

// Use for indexed navigation state
struct TransactionHistoryIndexPage: Hashable {
    let number: Int
    let total: Int
}

// Use for linked navigation state
struct TransactionHistoryLinkedPage: Hashable {
    let next: String?
}
