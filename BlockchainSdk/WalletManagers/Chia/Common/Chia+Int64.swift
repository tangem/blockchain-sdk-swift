//
//  Chia+Int64.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 25.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

extension Int64 {
    /// Convert amount value for use in ClvmProgram for serialization
    /// - Returns: Binary data encoded
    var chiaEncoded: Data {
        let unsafeDataValue = withUnsafeBytes(of: self) { Data($0) }.reversed().drop(while: { $0 == 0x00 })
        let serializeValue = BigInt(self).serialize()
        return (unsafeDataValue.first ?? 0x00) >= 0x80 ? serializeValue : serializeValue.dropFirst()
    }
}
