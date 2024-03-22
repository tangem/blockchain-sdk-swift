//
//  NexaScriptBuilder.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 22.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

/// Use this build for wotk the `p2st` as `Pay To Script Template` scripts
/// Documents: https://spec.nexa.org/addresses/scriptTemplates/
struct NexaScriptBuilder {
    func outputScript(publicKey: Data) throws -> Data {
        let compressedKey = try Secp256k1Key(with: publicKey).compress()
        // Add first byte as the PublicKey count
        let pkScriptData = try BitcoinScriptBuilder().appendData(compressedKey).getData()
        let hashScriptData = pkScriptData.sha256Ripemd160
        
        // Same as PUSH(HASH160(PUSH(publicKey)))
        let hashedPublicKeyScriptData = try BitcoinScriptBuilder().appendData(hashScriptData).getData()

        let script = try BitcoinScriptBuilder()
            .append(.OP_FALSE)
            .append(.OP_1)
            .appendData(hashedPublicKeyScriptData)
            .getData()
        
        let outputScript = try BitcoinScriptBuilder().appendData(script).getData()
        return outputScript
    }
}
