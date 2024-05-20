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
        let balance: Decimal
    }

    let hbarBalance: Decimal
    let tokenBalances: [TokenBalance]
}
