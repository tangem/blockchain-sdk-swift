//
//  WithdrawalValidator.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 12.02.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public protocol WithdrawalValidator {
    func withdrawalWarning(amount: Amount, fee: Amount) -> WithdrawalWarning?
}

public struct WithdrawalWarning {
    public let warningMessage: String
    public let reduceMessage: String
    public var ignoreMessage: String? = nil
    public let suggestedReduceAmount: Amount
}

