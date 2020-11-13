//
//  Token.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 13.04.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public struct Token {
    public let currencySymbol: String
    public let contractAddress: String
    public let decimalCount: Int
    public let displayName: String
    
    public private(set) var amount: Amount?
    
    public var isEmpty: Bool {
        guard let amount = amount, amount.value == 0 else {
            return false
        }
        
        return true
    }
    
    init(with tokenData: TokenData, displayName: String) {
        currencySymbol = tokenData.symbol
        contractAddress = tokenData.contractAddress
        decimalCount = tokenData.decimal
        self.displayName = displayName
    }
    
    mutating func set(amountValue: Decimal) {
        amount = Amount(with: self, value: amountValue)
    }
    
    mutating func clearAmount() {
        amount = nil
    }
}

extension Token: AmountStringConvertible {
    public var amountDescription: String {
        return amount?.description ?? "-"
    }
}
