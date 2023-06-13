//
//  BaseWalletType.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 13.06.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public protocol BaseWalletType {
    var blockchain: Blockchain { get }

    var amounts: [Amount.AmountType: Amount] { get set }
    var transactions: [Transaction] { get set }
}

// MARK: - Helping methods

extension BaseWalletType {

    // MARK: - Transactions

//    public var hasPendingTx: Bool {
//        return !transactions.filter { $0.status == .unconfirmed }.isEmpty
//    }

    // MARK: - Amounts

    public mutating func add(coinValue: Decimal) {
        let coinAmount = Amount(with: blockchain, type: .coin, value: coinValue)
        add(amount: coinAmount)
    }

    public mutating func add(reserveValue: Decimal) {
        let reserveAmount = Amount(with: blockchain, type: .reserve, value: reserveValue)
        add(amount: reserveAmount)
    }

    @discardableResult
    public mutating func add(tokenValue: Decimal, for token: Token) -> Amount {
        let tokenAmount = Amount(with: token, value: tokenValue)
        add(amount: tokenAmount)
        return tokenAmount
    }

    public mutating func add(amount: Amount) {
        amounts[amount.type] = amount
    }
}
