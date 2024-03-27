//
//  RadiantCashTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 14.02.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import WalletCore

class RadiantCashTransactionBuilder {
    let walletPublicKey: Data
    let decimalValue: Decimal
    
    var utxo: [ElectrumUTXO] = []
    
    // MARK: - Init
    
    init(walletPublicKey: Data, decimalValue: Decimal) throws {
        self.walletPublicKey = try Secp256k1Key(with: walletPublicKey).compress()
        self.decimalValue = decimalValue
    }
    
    // MARK: - Implementation
    
    func update(utxo: [ElectrumUTXO]) {
        self.utxo = utxo
    }
    
    func buildForSign(transaction: Transaction) throws -> [Data] {
        let outputScript = buildOutputScript(address: transaction.sourceAddress)
        let unspents = buildUnspents(with: [outputScript])
        
        let txForPreimage = RadiantAmountUnspentTransaction(
            decimalValue: decimalValue,
            amount: transaction.amount,
            fee: transaction.fee,
            unspents: unspents
        )
        
        let hashes = try unspents.enumerated().map { (index, _) in
            let preImageHash = try buildPreImageHashe(
                with: txForPreimage,
                targetAddress: transaction.destinationAddress,
                sourceAddress: transaction.sourceAddress,
                index: index
            )
            
            return preImageHash.sha256().sha256()
        }
        
        return hashes
    }
    
    func buildForSend(transaction: Transaction, signatures: [Data], isDer: Bool) throws -> Data {
        let outputScripts = try buildSignedScripts(
            signatures: signatures,
            publicKey: walletPublicKey,
            isDer: false
        )
        
        let unspents = buildUnspents(with: outputScripts)
        
        let txForSigned = RadiantAmountUnspentTransaction(
            decimalValue: decimalValue,
            amount: transaction.amount,
            fee: transaction.fee,
            unspents: unspents
        )
        
        let rawTransaction = try buildRawTransaction(
            with: txForSigned,
            targetAddress: transaction.destinationAddress,
            changeAddress: transaction.changeAddress,
            index: nil
        )
        
        return rawTransaction
    }
    
    // MARK: - Build Transaction Data
    
    /// Build preimage hashes for sign transaction with specify Radiant blockchain (etc. HashOutputHashes)
    /// - Parameters:
    ///   - tx: Union of unspents amount & change transaction
    ///   - targetAddress
    ///   - sourceAddress
    ///   - index: position image for output
    /// - Returns: Hash of one preimage
    private func buildPreImageHashe(
        with tx: RadiantAmountUnspentTransaction,
        targetAddress: String,
        sourceAddress: String,
        index: Int
    ) throws -> Data {
        
        var txToSign = Data()
        
        // version
        txToSign.append(contentsOf: [UInt8(0x01),UInt8(0x00),UInt8(0x00),UInt8(0x00)])

        //hashPrevouts (32-byte hash)
        writePrevoutHash(tx.unspents, into: &txToSign)
        
        //hashSequence (32-byte hash), ffffffff only
        writeSequenceHash(tx.unspents, into: &txToSign)
        
        //outpoint (32-byte hash + 4-byte little endian)
        let currentOutput = tx.unspents[index]
        txToSign.append(contentsOf: currentOutput.hash.reversed())
        txToSign.append(contentsOf: currentOutput.outputIndex.bytes4LE)
        
        //scriptCode of the input (serialized as scripts inside CTxOuts)
        let scriptCode = buildOutputScript(address: sourceAddress)
        
        txToSign.append(scriptCode.count.byte)
        txToSign.append(contentsOf: scriptCode)
        
        //value of the output spent by this input (8-byte little endian)
        txToSign.append(contentsOf: currentOutput.amount.bytes8LE)
        
        //nSequence of the input (4-byte little endian), ffffffff only
        txToSign.append(contentsOf: [UInt8(0xff),UInt8(0xff),UInt8(0xff),UInt8(0xff)])
        
        //hashOutputHashes (32-byte hash)
        try writeHashOutputHashes(
            amount: tx.amountSatoshiDecimalValue,
            sourceAddress: sourceAddress,
            targetAddress: targetAddress,
            change: tx.changeSatoshiDecimalValue,
            into: &txToSign
        )
        
        //hashOutputs (32-byte hash)
        try writeHashOutput(
            amount: tx.amountSatoshiDecimalValue,
            sourceAddress: sourceAddress,
            targetAddress: targetAddress,
            change: tx.changeSatoshiDecimalValue,
            into: &txToSign
        )
        
        //nLocktime of the transaction (4-byte little endian)
        txToSign.append(contentsOf: [UInt8(0x00),UInt8(0x00),UInt8(0x00),UInt8(0x00)])
        
        //sighash type of the signature (4-byte little endian)
        txToSign.append(contentsOf: [UInt8(0x41),UInt8(0x00),UInt8(0x00),UInt8(0x00)])
        
        return txToSign
    }
    
    /// Build raw transaction data without specify Radiant blockchain (etc. BitcoinCash)
    /// - Parameters:
    ///   - tx: Union of unspents amount & change transaction
    ///   - targetAddress
    ///   - changeAddress
    ///   - index: index of input transaction (specify nil value)
    /// - Returns: Raw transaction data
    private func buildRawTransaction(
        with tx: RadiantAmountUnspentTransaction,
        targetAddress: String,
        changeAddress: String,
        index: Int?
    ) throws -> Data {
        var txBody = Data()
        
        // version
        txBody.append(contentsOf: [UInt8(0x01),UInt8(0x00),UInt8(0x00),UInt8(0x00)])
                                                                                            
        //01
        txBody.append(tx.unspents.count.byte)
        
        //hex str hash prev btc
        for (inputIndex, input) in tx.unspents.enumerated() {
            let hashKey: [UInt8] = input.hash.reversed()
            txBody.append(contentsOf: hashKey)
            txBody.append(contentsOf: input.outputIndex.bytes4LE)
            
            if (index == nil) || (inputIndex == index) {
                txBody.append(input.outputScript.count.byte)
                txBody.append(contentsOf: input.outputScript)
            } else {
                txBody.append(UInt8(0x00))
            }
            
            //ffffffff
            txBody.append(contentsOf: [UInt8(0xff),UInt8(0xff),UInt8(0xff),UInt8(0xff)]) // sequence
        }
        
        //02
        let outputCount = tx.changeSatoshiDecimalValue == 0 ? 1 : 2
        txBody.append(outputCount.byte)
        
        //8 bytes
        txBody.append(contentsOf: tx.amountSatoshiDecimalValue.bytes8LE)
        
        let outputScriptBytes = buildOutputScript(address: targetAddress)
        
        //hex str 1976a914....88ac
        txBody.append(outputScriptBytes.count.byte)
        txBody.append(contentsOf: outputScriptBytes)
        
        if tx.changeSatoshiDecimalValue != 0 {
            //8 bytes of change satoshi value
            txBody.append(contentsOf: tx.changeSatoshiDecimalValue.bytes8LE)
            
            let outputScriptChangeBytes = buildOutputScript(address: changeAddress)
            
            txBody.append(outputScriptChangeBytes.count.byte)
            txBody.append(contentsOf: outputScriptChangeBytes)
        }
        
        //00000000
        txBody.append(contentsOf: [UInt8(0x00),UInt8(0x00),UInt8(0x00),UInt8(0x00)])
        
        return txBody
    }
    
    private func buildUnspents(with outputScripts: [Data]) -> [RadiantUnspentTransaction] {
        utxo
            .enumerated()
            .compactMap { index, txRef  in
                let hash = Data(hex: txRef.hash)
                let outputScript = outputScripts.count == 1 ? outputScripts.first! : outputScripts[index]
                return RadiantUnspentTransaction(
                    amount: txRef.value.uint64Value,
                    outputIndex: txRef.position,
                    hash: hash,
                    outputScript: outputScript
                )
            }
    }
    
    /// Default implementation BitcoinCash signed scripts
    func buildSignedScripts(signatures: [Data], publicKey: Data, isDer: Bool = false) throws -> [Data] {
        var scripts: [Data] = .init()
        scripts.reserveCapacity(signatures.count)
        for signature in signatures {
            var signDer: Data = signature
            
            if !isDer {
                signDer = try Secp256k1Signature(with: signature).serializeDer()
            }
            
            var script = Data()
            script.append((signDer.count+1).byte)
            script.append(contentsOf: signDer)
            script.append(UInt8(0x41))
            script.append(UInt8(0x21))
            script.append(contentsOf: publicKey)
            scripts.append(script)
        }
        
        return scripts
    }
    
    /// Lock script for output transaction for address
    private func buildOutputScript(address: String) -> Data {
        WalletCore.BitcoinScript.lockScriptForAddress(address: address, coin: WalletCore.CoinType.bitcoinCash).data
    }
    
    private func writePrevoutHash(_ unspents: [RadiantUnspentTransaction], into txToSign: inout Data) {
        let prevouts = Data(unspents.map {
            Data($0.hash.reversed()) + $0.outputIndex.bytes4LE
        }.joined())
        
        let hashPrevouts = prevouts.sha256().sha256()
        txToSign.append(contentsOf: hashPrevouts)
    }
    
    private func writeSequenceHash(_ unspents: [RadiantUnspentTransaction], into txToSign: inout Data) {
        let sequence = Data(repeating: UInt8(0xFF), count: 4 * unspents.count)
        let hashSequence = sequence.sha256().sha256()
        txToSign.append(contentsOf: hashSequence)
    }
    
    /// Default BitcoinCash implementation for set hash output values transaction data
    private func writeHashOutput(
        amount: Decimal,
        sourceAddress: String,
        targetAddress: String,
        change: Decimal,
        into txToSign: inout Data
    ) throws {
        //hashOutputs (32-byte hash)
        var outputs = Data()
        outputs.append(contentsOf: amount.bytes8LE)
        
        let sendScript = buildOutputScript(address: targetAddress)
        
        outputs.append(sendScript.count.byte)
        outputs.append(contentsOf: sendScript)
        
        //output for change (if any)
        if change != 0 {
            outputs.append(contentsOf: change.bytes8LE)
            
            let changeOutputScriptBytes = buildOutputScript(address: sourceAddress)
            
            outputs.append(changeOutputScriptBytes.count.byte)
            outputs.append(contentsOf: changeOutputScriptBytes)
        }
        
        let hashOutput = outputs.sha256().sha256()
        
        // Write bytes
        txToSign.append(contentsOf: hashOutput)
    }
    
    /// Specify for radiant blockchain
    /// See comment here for how it works https://github.com/RadiantBlockchain/radiant-node/blob/master/src/primitives/transaction.h#L493
    /// Since your transactions won't contain pushrefs, it will be very simple, like the commit I sent above
    private func writeHashOutputHashes(
        amount: Decimal,
        sourceAddress: String,
        targetAddress: String,
        change: Decimal,
        into txToSign: inout Data
    ) throws {
        let zeroRef = [Byte](repeating: 0, count: 32)
        
        //hashOutputs (32-byte hash)
        var outputs = Data()
        
        outputs.append(contentsOf: amount.bytes8LE)
        
        let sendScript = buildOutputScript(address: targetAddress)
        
        // Hash of the locking script
        let scriptHash = sendScript.sha256().sha256()
        outputs.append(contentsOf: scriptHash)
        
        outputs.append(0.bytes4LE)
        
        // Add zeroRef 32 bytes
        outputs.append(contentsOf: zeroRef)
        
        //output for change (if any)
        if change != 0 {
            outputs.append(contentsOf: change.bytes8LE)
            
            let changeOutputScriptBytes = buildOutputScript(address: sourceAddress)
            
            // Hash of the locking script
            let changeScriptHash = changeOutputScriptBytes.sha256().sha256()
            outputs.append(contentsOf: changeScriptHash)
            
            outputs.append(0.bytes4LE)
            
            // Add zeroRef 32 bytes
            outputs.append(contentsOf: zeroRef)
        }
        
        let hashOutputHash = outputs.sha256().sha256()
        
        // Write bytes
        txToSign.append(contentsOf: hashOutputHash)
    }
}
