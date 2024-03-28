//
//  RadiantAmountUnspentTransaction.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 27.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct RadiantAmountUnspentTransaction {
    private(set) var decimalValue: Decimal
    private(set) var amount: Amount
    private(set) var fee: Fee
    private(set) var unspents: [RadiantUnspentTransaction]
    
    var amountSatoshiDecimalValue: Decimal {
        (amount.value * decimalValue).roundedDecimalNumber.decimalValue
    }
    
    var feeSatoshiDecimalValue: Decimal {
        (fee.amount.value * decimalValue).roundedDecimalNumber.decimalValue
    }
    
    var changeSatoshiDecimalValue: Decimal {
        calculateChange(unspents: unspents, amountSatoshi: amountSatoshiDecimalValue, feeSatoshi: feeSatoshiDecimalValue)
    }
    
    private func calculateChange(
        unspents: [RadiantUnspentTransaction],
        amountSatoshi: Decimal,
        feeSatoshi: Decimal
    ) -> Decimal {
        let fullAmountSatoshi = Decimal(unspents.reduce(0, {$0 + $1.amount}))
        return fullAmountSatoshi - amountSatoshi - feeSatoshi
    }
}
