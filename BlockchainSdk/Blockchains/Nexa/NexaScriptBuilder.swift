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
    
    // Same as PUSH(OP_FALSE + OP_1 + PUSH(HASH160(PUSH(publicKey))))
    func outputScript(publicKey: Data) throws -> Data {
        let compressedKey = try Secp256k1Key(with: publicKey).compress()
        // Add first byte as the PublicKey count
        let scriptData = try BitcoinScriptBuilder().append(compressedKey).build().data
        let hashScriptData = scriptData.sha256Ripemd160

        let script = try BitcoinScriptBuilder()
            .append(.OP_FALSE)
            .append(.OP_1)
            .append(hashScriptData)
            .build().data
        
        let outputScript = try BitcoinScriptBuilder().append(script).build().data
        print("outputScript ->>", outputScript.hexString)
        return outputScript
    }
}
