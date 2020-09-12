//
//  Amount.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 13.04.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public struct Amount: CustomStringConvertible, Equatable {
    public enum AmountType {
        case coin
        case token
        case reserve
    }
    
    public let type: AmountType
    public let currencySymbol: String
    public var value: Decimal
    public let decimals: Int
    
    public var description: String {
        return "\(value.rounded(decimals)) \(currencySymbol)"
    }
    
    public init(with blockchain: Blockchain, address: String, type: AmountType = .coin, value: Decimal) {
        self.type = type
        currencySymbol = blockchain.currencySymbol
        decimals = blockchain.decimalCount
        self.value = value
    }
    
    public init(with token: Token, value: Decimal) {
        type = .token
        currencySymbol = token.currencySymbol
        decimals = token.decimalCount
        self.value = value
    }
    
    public init(with amount: Amount, value: Decimal) {
        type = amount.type
        currencySymbol = amount.currencySymbol
        decimals = amount.decimals
        self.value = value
    }
    
    public static func ==(lhs: Amount, rhs: Amount) -> Bool {
        if lhs.type != rhs.type {
            return false
        }
        
        return lhs.value == rhs.value
    }
    
    static public func -(l: Amount, r: Amount) -> Amount {
        if l.type != r.type {
            return l
        }
        return Amount(with: l, value: l.value - r.value)
    }
    
    static public func +(l: Amount, r: Amount) -> Amount {
        if l.type != r.type {
            return l
        }
        return Amount(with: l, value: l.value + r.value)
    }
}
