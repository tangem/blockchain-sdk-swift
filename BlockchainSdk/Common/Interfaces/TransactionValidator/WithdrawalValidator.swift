//
//  WithdrawalValidator.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 12.02.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public protocol WithdrawalValidator {
    @available(*, deprecated, message: "Use WithdrawalValidator.withdrawalSuggestion")
    func validateWithdrawalWarning(amount: Amount, fee: Amount) -> WithdrawalWarning?
    
    func withdrawalSuggestion(for transaction: Transaction) -> WithdrawalSuggestion?
}

public struct WithdrawalWarning: Hashable {
    public let warningMessage: String
    public let reduceMessage: String
    public var ignoreMessage: String? = nil
    public let suggestedReduceAmount: Amount
}

public enum WithdrawalSuggestion {
    case optionalAmountChange(newAmount: Amount)
    case mandatoryAmountChange(newAmount: Amount, maxUtxo: Int)
}
