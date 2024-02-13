//
//  CreatedAccount.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 13.02.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

/// - Note: Feel free to add required properties and factory methods for other blockchains.
public struct CreatedAccount {
    let accountId: String

    /// - Note: Keep this constructor private to avoid API misuse.
    private init(accountId: String) {
        self.accountId = accountId
    }
}

// MARK: - Public API for consumers

public extension CreatedAccount {
    static func forHedera(accountId: String) -> Self {
        self.init(accountId: accountId)
    }
}
