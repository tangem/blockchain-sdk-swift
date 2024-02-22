//
//  UnixTimestamp.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 22.02.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

/// UNIX timestamp, with optional fractional part.
struct UnixTimestamp {
    let integerPart: UInt
    let fractionalPart: UInt
}

// MARK: - Private implementation

private extension UnixTimestamp {
    init?(signedIntegerPart: Int, signedFractionalPart: Int) {
        // UNIX timestamps can't be negative
        guard signedIntegerPart >= 0, signedFractionalPart >= 0 else {
            return nil
        }

        self.init(integerPart: UInt(signedIntegerPart), fractionalPart: UInt(signedFractionalPart))
    }
}

// MARK: - Convenience extensions

extension UnixTimestamp {
    init?<T>(timestamp: T) where T: BinaryInteger {
        self.init(signedIntegerPart: Int(timestamp), signedFractionalPart: 0)
    }

    /// - Warning: `NSDate`/`Swift.Date` provides only milliseconds precision https://stackoverflow.com/questions/46161848
    init?(date: Date) {
        let dateComponents = date.dateComponents

        self.init(
            signedIntegerPart: dateComponents.second ?? 0,
            signedFractionalPart: dateComponents.nanosecond ?? 0
        )
    }
}

// MARK: - ExpressibleByIntegerLiteral protocol conformance

extension UnixTimestamp: ExpressibleByIntegerLiteral {
    typealias IntegerLiteralType = UInt

    init(integerLiteral value: IntegerLiteralType) {
        self.init(integerPart: value, fractionalPart: 0)
    }
}
