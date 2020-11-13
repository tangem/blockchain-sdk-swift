//
//  Amount.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 13.04.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public struct Amount: CustomStringConvertible, Equatable, Comparable {
    public enum AmountType {
        case coin
        case token(value: Token)
        case reserve
        
        public var token: Token? {
            if case let .token(token) = self {
                return token
            }
            return nil
        }
    }
    
    public let type: AmountType
    public let currencySymbol: String
    public var value: Decimal?
    public let decimals: Int

    public var isEmpty: Bool {
        if let value = value, value == 0 {
            return true
        }
        
        return false
    }
    
    public var hasValue: Bool {
        return value != nil
    }
    
    public var description: String {
        guard let value = value else {
            return "-"
        }
        if value == 0 {
            return "0.00 \(currencySymbol)"
        }
        return "\(value.rounded(decimals)) \(currencySymbol)"
    }
    
    public init(with blockchain: Blockchain, address: String, type: AmountType = .coin, value: Decimal? = nil) {
        self.type = type
        currencySymbol = blockchain.currencySymbol
        decimals = blockchain.decimalCount
        self.value = value
    }
    
    public init(with token: Token, value: Decimal? = nil) {
        type = .token(value: token)
        currencySymbol = token.symbol
        decimals = token.decimalCount
        self.value = value
    }
    
    public init(with amount: Amount, value: Decimal? = nil) {
        type = amount.type
        currencySymbol = amount.currencySymbol
        decimals = amount.decimals
        self.value = value
    }
    
    public mutating func clear() {
        value = nil
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
    
    public static func < (lhs: Amount, rhs: Amount) -> Bool {
        if lhs.type != rhs.type {
            fatalError("Compared amounts must be the same type")
        }
        
        return lhs.value < rhs.value
    }
    
}

extension Amount.AmountType: Equatable, Hashable {
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .coin:
            hasher.combine("coin")
        case .reserve:
            hasher.combine("reserve")
        case .token(let value):
            hasher.combine(value.hashValue)
        }
    }
    
    public static func == (lhs: Amount.AmountType, rhs: Amount.AmountType) -> Bool {
        switch (lhs, rhs) {
        case (.coin, .coin):
            return true
        case (.reserve, .reserve):
            return true
        case (.token(let lv), .token(let rv)):
            if lv.currencySymbol == rv.currencySymbol,
                lv.contractAddress == rv.contractAddress {
                return true
            }
        default:
            return false
        }
    }
}
