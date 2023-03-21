//
//  Fee.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 21.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public protocol FeeParameters {}

public struct Fee {
    public let amount: Amount
    public let parameters: FeeParameters?
    
    public init(_ fee: Amount, parameters: FeeParameters? = nil) {
        self.amount = fee
        self.parameters = parameters
    }
}

// MARK: - Hashable

extension Fee: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(amount)
    }
    
    public static func == (lhs: Fee, rhs: Fee) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
}

// MARK: - Helpers

extension Fee {
    public func increased(by value: Decimal) -> Self {
        let newAmount = Amount(with: amount, value: amount.value + value)
        return Fee(newAmount, parameters: parameters)
    }
}
