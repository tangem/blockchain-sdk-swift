//
//  BitcoinScriptBuilder.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 28.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

class BitcoinScriptBuilder {
    private var data = Data()
    private let scriptChunkHelper = ScriptChunkHelper()
    
    func build() throws -> BitcoinScript {
        let chunks = try parseData(data)
        return BitcoinScript(chunks: chunks, data: data)
    }

    @discardableResult
    func append(_ opcode: OpCode) throws -> Self {
        guard !BitcoinScriptBuilder.invalidOpCodes.contains(where: { $0 == opcode }) else {
            throw BitcoinScriptBuilderError.invalidOpCode
        }

        data += Data(opcode.value)
        return self
    }

    @discardableResult
    func append(_ newData: Data) throws -> Self {
        guard !newData.isEmpty else {
            throw BitcoinScriptBuilderError.invalidData
        }

        let scriptData = try scriptChunkHelper.scriptData(for: newData, preferredLengthEncoding: -1)
        data += scriptData
        return self
    }

    func parseData(_ data: Data) throws -> [BitcoinScriptChunk] {
        guard !data.isEmpty else {
            return []
        }

        var chunks = [BitcoinScriptChunk]()

        var i: Int = 0
        let count: Int = data.count

        while i < count {
            // Exit if failed to parse
            let chunk = try scriptChunkHelper.parseChunk(from: data, offset: i)
            chunks.append(chunk)
            i += chunk.range.count
        }
        return chunks
    }
}

enum BitcoinScriptBuilderError: Error {
    case invalidOpCode
    case invalidData
}

private extension BitcoinScriptBuilder {
    static let invalidOpCodes: [OpCode] = [
        .OP_PUSHDATA1,
        .OP_PUSHDATA2,
        .OP_PUSHDATA4,
        .OP_INVALIDOPCODE
    ]
}
