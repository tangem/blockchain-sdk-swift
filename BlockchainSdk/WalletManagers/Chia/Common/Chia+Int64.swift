//
//  Chia+Int64.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 25.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

extension Int64 {
    /// Convert amount value for use in ClvmProgram for serialization
    /// - Returns: Binary data encoded
    var chiaEncoded: Data {
        let data = withUnsafeBytes(of: self) { Data($0) }
        let result = data.bytes.reversed().drop(while: { $0 == 0x00 })
        return Data(result)
    }
}
