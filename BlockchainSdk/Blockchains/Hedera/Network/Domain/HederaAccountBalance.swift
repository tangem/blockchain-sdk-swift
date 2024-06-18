//
//  HederaAccountBalance.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 06.04.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct HederaAccountBalance {
    struct TokenBalance {
        let contractAddress: String
        /// In atomic units.
        let balance: Int
        let decimalCount: Int
    }

    /// In atomic units (i.e. Tinybars).
    let hbarBalance: Int
    /// Unlike REST endpoint for HBAR balance (`api/v1/balances?account.id={account_id}`), REST endpoint for HTS tokens 
    /// balances (`api/v1/accounts/{account_id}/tokens?limit={token_limit}`) has no direct equivalent in the GRPC API.
    /// Therefore, there may be cases when the HBAR balance can be obtained while HTS token balances can't
    /// (for example, when all REST endpoints are unavailable). In such cases, the resulting error for HTS tokens balances
    /// fetching is stored using the Result type (in this filed, `tokenBalances`) and must be handled appropriately.
    let tokenBalances: Result<[TokenBalance], Swift.Error>
}
