//
//  AssetRequirementsCondition.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 23.04.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public enum AssetRequirementsCondition {
    /// - Note: The exact value of the fee for this type of condition is unknown.
    case paidTransaction
    case paidTransactionWithFee(feeAmount: Amount)
    @available(*, unavailable, message: "Token trust lines support not implemented yet")
    case minimumBalanceChange(newMinimumBalance: Amount)
}
