//
//  BitcoinMultisigScriptBuilder.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 22.03.2024.
//

import Foundation

struct BitcoinMultisigScriptBuilder {
    func makeMultisig(publicKeys: [Data], signaturesRequired: Int) throws -> BitcoinScript {
        let publicKeys = publicKeys.sorted(by: { $0.lexicographicallyPrecedes($1) })

        // First make sure the arguments make sense.
        // We need at least one signature
        guard signaturesRequired > 0 else {
            throw BlockchainSdkError.failedToCreateMultisigScript
        }

        // And we cannot have more signatures than available pubkeys.
        guard publicKeys.count >= signaturesRequired else {
            throw BlockchainSdkError.failedToCreateMultisigScript
        }

        // Both M and N should map to OP_<1..16>
        let mOpcode: OpCode = OpCodeFactory.opcode(for: signaturesRequired)
        let nOpcode: OpCode = OpCodeFactory.opcode(for: publicKeys.count)

        guard mOpcode != .OP_INVALIDOPCODE else {
            throw BlockchainSdkError.failedToCreateMultisigScript
        }

        guard nOpcode != .OP_INVALIDOPCODE else {
            throw BlockchainSdkError.failedToCreateMultisigScript
        }

        let scriptBuilder = BitcoinScriptBuilder()

        try scriptBuilder.append(mOpcode)
        for pubkey in publicKeys {
            try scriptBuilder.append(pubkey)
        }
        try scriptBuilder.append(nOpcode)
        try scriptBuilder.append(.OP_CHECKMULTISIG)

        let bitcoinScript = try scriptBuilder.build()
        return bitcoinScript
    }
}
