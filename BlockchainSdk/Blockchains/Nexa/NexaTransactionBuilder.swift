//
//  NexaTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 19.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BitcoinCore

// Decoder: https://explorer.nexa.org/decoder
class NexaTransactionBuilder {
    static let maxUTXO: Int = 250
    
    private let publicKey: Data
    private var outputs: [ElectrumUTXO] = []
    private var decimalValue: Decimal {
        Blockchain.nexa.decimalValue
    }
    
    init(publicKey: Data) {
        self.publicKey = publicKey
    }
    
    func update(outputs: [ElectrumUTXO]) {
        self.outputs = outputs
    }
    
    func availableToSpendAmount(amount: Decimal) -> Decimal {
        guard outputs.count > NexaTransactionBuilder.maxUTXO else {
            return amount
        }
        
        let availableToSend = outputs.reduce(0, { $0 + $1.value }) / decimalValue
        return availableToSend
    }

    func buildForSign(transaction: Transaction) throws -> Data {
        let satoshiAmount = transaction.amount.value / decimalValue
        let satoshiFee = transaction.fee.amount.value / decimalValue
        let (outputs, sum) = collectOutputs(toSpendAmount: satoshiAmount)

        // Make the inputs from the outputs to spend it
        let vin = outputs.enumerated().map { index, output in
            NexaPreImageInput(
                prevTxId: Data.reverse(hexString: output.outpoint),
                value: output.value.uint64Value
            )
        }
        
        let lockingScript = try NexaScriptBuilder().lockScript(address: transaction.destinationAddress)
        // Make the outputs into tx. Spend and change
        var vout = [
            NexaOutput(value: satoshiAmount.uint64Value, lockingScript: lockingScript)
        ]
        
        let change = sum - satoshiAmount - satoshiFee
        if change > 546 { // change > dust
            let walletLockScript = try NexaScriptBuilder().lockScript(address: transaction.sourceAddress)
            vout.append(NexaOutput(value: change.uint64Value, lockingScript: walletLockScript))
        }
        
        // OP_FROMALTSTACK + OP_CHECKSIGVERIFY
        let preImageSubscript = try NexaScriptBuilder().preImageSubscript()
        let hex = serializeToSign(inputs: vin, outputs: vout, preImageSubscript: preImageSubscript, locktime: .max)
        
        return hex
    }

    func buildForSend(transaction: Transaction, signature: SignatureInfo) throws -> Data {
        let amount = transaction.amount.value / decimalValue
        let (outputs, sum) = collectOutputs(toSpendAmount: amount)
        let unlockScript = try NexaScriptBuilder().unlockScript(publicKey: publicKey, signature: signature.signature)

        // Make the inputs from the outputs to spend it
        let vin = outputs.enumerated().map { index, output in
            NexaInput(
                prevTxId: Data.reverse(hexString: output.outpoint),
                unlockingScript: unlockScript,
                value: output.value.uint64Value,
                sequence: UInt32(index)
            )
        }
        
        let lockingScript = try NexaScriptBuilder().lockScript(address: transaction.destinationAddress)
        // Make the outputs into tx. Spend and change
        var vout = [
            NexaOutput(value: amount.uint64Value, lockingScript: lockingScript)
        ]
        
        let change = sum - amount
        if change > 0 {
            let walletLockScript = try NexaScriptBuilder().lockScript(address: transaction.sourceAddress)
            vout.append(NexaOutput(value: change.uint64Value, lockingScript: walletLockScript))
        }
        
        let hex = serialize(vin: vin, vout: vout)
        return hex
    }
}

// MARK: - UTXO

private extension NexaTransactionBuilder {
    // TODO: Make a manager for work with all utxo blochains
    func collectOutputs(toSpendAmount amount: Decimal) -> (outputs: [ElectrumUTXO], sum: Decimal) {
        var outputsToUse: [ElectrumUTXO] = []
        var outputsToUseSum: Decimal = 0
        for output in outputs {
            outputsToUse.append(output)
            outputsToUseSum += output.value
            
            // If enough to spend
            if outputsToUseSum >= amount {
                return (outputsToUse, outputsToUseSum)
            }
        }
        
        // We should return it early
        assertionFailure("Not enough outputs count: \(outputs.count) to spend amount: \(amount)")
        return (outputsToUse, outputsToUseSum)
    }
}

// MARK: - Serialization

private extension NexaTransactionBuilder {
    // https://spec.nexa.org/transactions/1transaction/
    func serializeToSign(inputs: [NexaPreImageInput], outputs: [NexaOutput], preImageSubscript: Data, locktime: UInt32) -> Data {
        var data = Data()
        
        // Version in 1 byte.
        data += UInt8(0)
        data += inputs.flatMap { serialize(input: $0) }.getDoubleSha256()
        data += inputs.reduce(Data()) { $0 + $1.value }.getDoubleSha256()
        data += inputs.reduce(Data()) { $0 + $1.sequence }.getDoubleSha256()
        
        data += VarInt(preImageSubscript.count).serialized()
        data += preImageSubscript
        
        data += outputs.flatMap { serialize(output: $0) }.getDoubleSha256()

        data += locktime
        data += UInt8(0)

        return Data(data.getDoubleSha256().reversed())
    }
    
    // https://spec.nexa.org/transactions/1transaction/
    func serialize(vin: [NexaInput], vout: [NexaOutput]) -> Data {
        var data = Data()
        
        // Version in 1 byte.
        data += UInt8(0)
        data += VarInt(vin.count).serialized()
        data += vin.flatMap { serialize(input: $0) }
        data += VarInt(vout.count).serialized()
        data += vout.flatMap { serialize(output: $0) }
        data += UInt32.max
        
        return data
    }
    
    func serialize(input: NexaPreImageInput) -> Data {
        var data = Data()
        data += input.type
        data += input.prevTxId
        return data
    }
    
    func serialize(input: NexaInput) -> Data {
        var data = Data()
        data += input.type
        data += input.prevTxId
        data += VarInt(input.unlockingScript.count).serialized()
        data += input.unlockingScript
        data += input.sequence
        data += input.value
        
        return data
    }
    
    func serialize(output: NexaOutput) -> Data {
        var data = Data()
        data += output.type
        data += output.value
        data += VarInt(output.lockingScript.count).serialized()
        data += output.lockingScript
        
        return data
    }
}


// MARK: - Models

private extension NexaTransactionBuilder {
    struct NexaPreImageInput {
        // InputType(0) = TEMPLATE
        let type: UInt8 = UInt8(0)

        let prevTxId: Data
        let value: UInt64
        let sequence: UInt32 = .max
    }
    
    struct NexaInput {
        // InputType(0) = TEMPLATE
        let type: UInt8 = UInt8(0)
        
        /// Reserved outpoint from `utxo`
        let prevTxId: Data
        let unlockingScript: Data
        let value: UInt64
        let sequence: UInt32
    }
    
    struct NexaOutput {
        // OutputType(0) = p2pkh
        // OutputType(1) = p2st
        let type: UInt8 = UInt8(1)
        let value: UInt64
        let lockingScript: Data
    }
}
