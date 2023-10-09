//
//  BigUInt+.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 09.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import BigInt

extension BigUInt {
    init(_ decimal: Decimal) {
        if decimal == .zero {
            self = .zero
        } else if decimal == .greatestFiniteMagnitude {
            self = BigUInt(2).power(256) - 1
        } else {
            self = BigUInt(decimal.uint64Value)
        }
    }
}
