//
//  Decimal+.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 10.12.2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

extension Decimal {
    /// return 8 bytes of integer. LittleEndian  format
    var bytes8LE: [UInt8] {
        let int64value = (self.rounded(scale: 0) as NSDecimalNumber).intValue
        let bytes8 =  int64value.bytes8LE
        return Array(bytes8)
    }
    
    // TODO: Andrey Fedorov - Remove (IOS-6237)
    @available(*, deprecated, message: "May produce unexpected results due to non-fixed locale, use `init?(stringValue:)` instead")
    init?(_ string: String?) {
        guard let string = string else {
            return nil
        }
        
        self.init(string: string)
    }
    
    /// Parses given string using a fixed `en_US_POSIX` locale.
    /// - Note: Prefer this initializer to the `init?(string:locale:)` or `init?(_:)`.
    public init?(stringValue: String?) {
        guard let stringValue = stringValue else {
            return nil
        }

        self.init(string: stringValue, locale: .posixEnUS)
    }

    init?(_ int: Int?) {
        guard let int = int else {
            return nil
        }
        
        self.init(int)
    }
    
    init?(data: Data) {
        guard let uint64 = UInt64(data: data) else {
            return nil
        }
        
        self.init(uint64)
    }
    
    public mutating func round(scale: Int = 0, roundingMode: NSDecimalNumber.RoundingMode = .down) {
        var localCopy = self
        NSDecimalRound(&self, &localCopy, scale, roundingMode)
    }
    
    public func rounded(scale: Int = 0, roundingMode: NSDecimalNumber.RoundingMode = .down) -> Decimal {
        var result = Decimal()
        var localCopy = self
        NSDecimalRound(&result, &localCopy, scale, roundingMode)
        return result
    }
    
    public func rounded(blockchain: Blockchain) -> Decimal {
        return rounded(scale: Int(blockchain.decimalCount))
    }

    var int64Value: Int64 {
        decimalNumber.int64Value
    }

    var uint64Value: UInt64 {
        decimalNumber.uint64Value
    }

    var decimalNumber: NSDecimalNumber {
        self as NSDecimalNumber
    }

    var roundedDecimalNumber: NSDecimalNumber {
        rounded(roundingMode: .up) as NSDecimalNumber
    }
}

// MARK: - Private implementation

private extension Locale {
    /// Locale for string literals parsing.
    static let posixEnUS = Locale(identifier: "en_US_POSIX")
}
