//
//  BigUInt+.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 01.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import struct BigInt.BigUInt

extension BigUInt {
    /// 1. For integers only, will return `nil` if the value isn't an integer number.
    /// 2. The given value will be clamped in the `0..<2^256>` range.
    init?(decimal decimalValue: Decimal) {
        if decimalValue.isZero || decimalValue < .zero {
            // Clamping to the min representable value
            self = .zero
        } else if decimalValue >= .greatestFiniteMagnitude {
            // Clamping to the max representable value
            self = BigUInt(2).power(256) - 1
        } else {
            // We're using a fixed locale here to avoid any possible ambiguity with the string representation
            let stringValue = decimalValue.decimalNumber.description(withLocale: Locale.enUS)
            self.init(stringValue, radix: 10)
        }
    }
}

// MARK: - Convenience extensions

private extension Locale {
    static let enUS: Locale = Locale(identifier: "en_US")
}
