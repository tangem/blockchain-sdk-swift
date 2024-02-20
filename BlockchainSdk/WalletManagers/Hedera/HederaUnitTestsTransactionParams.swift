//
//  HederaUnitTestsTransactionParams.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 20.02.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import struct Hedera.Timestamp
import struct Hedera.AccountId

/// - Note: For use in unit tests only.
struct HederaUnitTestsTransactionParams: TransactionParams {
    let memo: String
    let txValidStart: Timestamp
    let nodeAccountIds: [AccountId]
}
