//
//  SignatureUtils.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 10.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

enum SignatureUtils {
    /// Helper method for unmarshal `secp256k1` signatures
    /// Will separate your signature on `r`, `s`, `v` and return their sum.
    /// - Parameters:
    ///   - hash: Hash which was signed
    ///   - signature: `secp256k1` signature
    ///   - publicKey: Non derived publicKey
    /// - Returns: The sum by `r + s + v`
    static func unmarshal(hash: Data, signature: Data, publicKey: Data) throws -> Data {
        let secpSignature = try Secp256k1Signature(with: signature)
        let (v, r, s) = try secpSignature.unmarshal(with: publicKey, hash: hash)
        return r + s + v
    }
}
