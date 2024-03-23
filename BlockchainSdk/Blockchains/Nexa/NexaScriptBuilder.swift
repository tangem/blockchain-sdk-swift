//
//  NexaScriptBuilder.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 22.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BitcoinCore

/// Use this build for wotk the `p2st` as `Pay To Script Template` scripts
/// Documents: https://spec.nexa.org/addresses/scriptTemplates/
struct NexaScriptBuilder {
    // Same as PUSH(OP_FALSE + OP_1 + PUSH(HASH160(PUSH(publicKey))))
    func outputScript(publicKey: Data) throws -> Data {
        // Make compressed Secp256k1Key through add first byte as the PublicKey count
        let scriptData = try BitcoinScriptBuilder().append([UInt8(0x02)] + publicKey).build().data
        let hashScriptData = scriptData.sha256Ripemd160

        let script = try BitcoinScriptBuilder()
            .append(.OP_FALSE)
            .append(.OP_1)
            .append(hashScriptData)
            .build().data
        
        let outputScript = try BitcoinScriptBuilder().append(script).build().data
        return outputScript
    }
    
    func lockScript(address: String) throws -> Data {
        guard let (prefix, hash) = CashAddrBech32.decode(address) else {
            return .init()
        }
        
        var script = hash
        _ = script.dropFirst()
        return script
    }
    
    func preImageSubscript() throws -> Data {
        try BitcoinScriptBuilder()
            .append(.OP_FROMALTSTACK)
            .append(.OP_CHECKSIGVERIFY)
            .build().data
    }
    
    func unlockScript(publicKey: Data, signature: Data) throws -> Data {
        let scriptData = try BitcoinScriptBuilder().append(publicKey).build().data
        
        return try BitcoinScriptBuilder()
            .append(scriptData)
            .append(signature)
            .build().data
    }
}
