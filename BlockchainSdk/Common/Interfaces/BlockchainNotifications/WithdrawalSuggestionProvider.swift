//
//  WithdrawalSuggestionProvider.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 12.02.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public protocol WithdrawalSuggestionProvider {
    @available(*, deprecated, message: "Use WithdrawalSuggestionProvider.withdrawalSuggestion")
    func validateWithdrawalWarning(amount: Amount, fee: Amount) -> WithdrawalWarning?
    
    func withdrawalSuggestion(amount: Amount, fee: Amount) -> WithdrawalSuggestion?
}

@available(*, deprecated, message: "Use WithdrawalSuggestionProvider.withdrawalSuggestion")
public struct WithdrawalWarning: Hashable {
    public let warningMessage: String
    public let reduceMessage: String
    public var ignoreMessage: String? = nil
    public let suggestedReduceAmount: Amount
}

public enum WithdrawalSuggestion: Hashable {
    case feeIsTooHigh(reduceAmountBy: Amount)
    case cardanoWillBeSendAlongToken(amount: Amount)
}
