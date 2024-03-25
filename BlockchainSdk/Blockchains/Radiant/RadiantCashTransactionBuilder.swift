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
    
    var unspentOutputs: [BitcoinUnspentOutput] = []
    
    // MARK: - Init
    
    init(walletPublicKey: Data, decimalValue: Decimal) throws {
        self.walletPublicKey = try Secp256k1Key(with: walletPublicKey).compress()
        self.decimalValue = decimalValue
    }
    
    // MARK: - Implementation
    
    func update(unspents: [BitcoinUnspentOutput]) {
        self.unspentOutputs = unspents
    }
    
    func buildForSign(transaction: Transaction) throws -> [Data] {
        guard let outputScript = buildOutputScript(address: transaction.sourceAddress) else {
            throw "RadiantCashTransactionBuilder outputScript error"
        }
        
        let unspents = buildUnspents(with: [outputScript])
        
        let amountSatoshi = transaction.amount.value * decimalValue
        let changeSatoshi = calculateChange(unspents: unspents, amountSatoshi: amountSatoshi, fee: transaction.fee.amount.value)
        
        var hashes = [Data]()
        
        for index in 0..<unspents.count {
            guard let tx = try? buildPreImageHashes(
                unspents: unspents,
                amount: amountSatoshi,
                change: changeSatoshi,
                targetAddress: transaction.destinationAddress,
                sourceAddress: transaction.sourceAddress,
                index: index
            ) else {
                throw WalletError.failedToBuildTx
            }
            
            let hash = tx.sha256().sha256()
            let reversedHash = Data(hash.reversed())
            hashes.append(reversedHash)
        }
        
        return hashes
    }
    
    func buildForSend(transaction: Transaction, signatures: [Data]) throws -> Data {
        guard let outputScripts = buildSignedScripts(signatures: signatures, publicKey: walletPublicKey) else {
            throw WalletError.failedToBuildTx
        }
        
        let unspents = buildUnspents(with: outputScripts)
        
        let amountSatoshi = transaction.amount.value * decimalValue
        let changeSatoshi = calculateChange(unspents: unspents, amountSatoshi: amountSatoshi, fee: transaction.fee.amount.value)
        
        let tx = try buildTxBody(
            unspents: unspents,
            amount: amountSatoshi,
            change: changeSatoshi,
            targetAddress: transaction.destinationAddress,
            changeAddress: transaction.changeAddress,
            index: nil
        )
        
        return tx
    }
    
    // MARK: - Build Transaction Data
    
    private func buildPreImageHashes(
        unspents: [RadiantUnspentTransaction],
        amount: Decimal,
        change: Decimal,
        targetAddress: String,
        sourceAddress: String,
        index: Int
    ) throws -> Data {
        
        var txToSign = Data()
        
        // version
        txToSign.append(contentsOf: [UInt8(0x01),UInt8(0x00),UInt8(0x00),UInt8(0x00)])

        //hashPrevouts (32-byte hash)
        writePrevoutHash(unspents, into: &txToSign)
        
        //hashSequence (32-byte hash), ffffffff only
        writeSequenceHash(unspents, into: &txToSign)
        
        //outpoint (32-byte hash + 4-byte little endian)
        let currentOutput = unspents[index]
        txToSign.append(contentsOf: currentOutput.hash.reversed())
        txToSign.append(contentsOf: currentOutput.outputIndex.bytes4LE)
        
        //scriptCode of the input (serialized as scripts inside CTxOuts)
        guard let scriptCode = buildOutputScript(address: sourceAddress) else { //build change out
            throw WalletError.failedToBuildTx
        }
        
        txToSign.append(scriptCode.count.byte)
        txToSign.append(contentsOf: scriptCode)
        
        //value of the output spent by this input (8-byte little endian)
        txToSign.append(contentsOf: currentOutput.amount.bytes8LE)
        
        //nSequence of the input (4-byte little endian), ffffffff only
        txToSign.append(contentsOf: [UInt8(0xff),UInt8(0xff),UInt8(0xff),UInt8(0xff)])
        
        //hashOutputHashes (32-byte hash)
        try writeHashOutputHashes(
            amount: amount,
            sourceAddress: sourceAddress,
            targetAddress: targetAddress,
            change: change,
            into: &txToSign
        )
        
        //hashOutputs (32-byte hash)
        try writeHashOutput(
            amount: amount,
            sourceAddress: sourceAddress,
            targetAddress: targetAddress,
            change: change,
            into: &txToSign
        )
        
        //nLocktime of the transaction (4-byte little endian)
        txToSign.append(contentsOf: [UInt8(0x00),UInt8(0x00),UInt8(0x00),UInt8(0x00)])
        
        //sighash type of the signature (4-byte little endian)
        txToSign.append(contentsOf: [UInt8(0x41),UInt8(0x00),UInt8(0x00),UInt8(0x00)])
        
        return txToSign
    }
    
    private func buildTxBody(
        unspents: [RadiantUnspentTransaction],
        amount: Decimal,
        change: Decimal,
        targetAddress: String,
        changeAddress: String,
        index: Int?
    ) throws -> Data {
        var txToSign = Data()
        // version
        txToSign.append(contentsOf: [UInt8(0x01),UInt8(0x00),UInt8(0x00),UInt8(0x00)])
                                                                                            
        //01
        txToSign.append(unspents.count.byte)
        
        //hex str hash prev btc
        
        for (inputIndex, input) in unspents.enumerated() {
            let hashKey: [UInt8] = input.hash.reversed()
            txToSign.append(contentsOf: hashKey)
            txToSign.append(contentsOf: input.outputIndex.bytes4LE)
            if (index == nil) || (inputIndex == index) {
                txToSign.append(input.outputScript.count.byte)
                txToSign.append(contentsOf: input.outputScript)
            } else {
                txToSign.append(UInt8(0x00))
            }
            //ffffffff
            txToSign.append(contentsOf: [UInt8(0xff),UInt8(0xff),UInt8(0xff),UInt8(0xff)]) // sequence
        }
        
        //02
        let outputCount = change == 0 ? 1 : 2
        txToSign.append(outputCount.byte)
        
        //8 bytes
        txToSign.append(contentsOf: amount.bytes8LE)
        
        guard let outputScriptBytes = buildOutputScript(address: targetAddress) else {
            throw WalletError.failedToBuildTx
        }
        
        //hex str 1976a914....88ac
        txToSign.append(outputScriptBytes.count.byte)
        txToSign.append(contentsOf: outputScriptBytes)
        
        if change != 0 {
            //8 bytes
            txToSign.append(contentsOf: change.bytes8LE)
            
            //hex str 1976a914....88ac
            guard let outputScriptChangeBytes = buildOutputScript(address: changeAddress) else {
                throw WalletError.failedToBuildTx
            }
            
            txToSign.append(outputScriptChangeBytes.count.byte)
            txToSign.append(contentsOf: outputScriptChangeBytes)
        }
        
        //00000000
        txToSign.append(contentsOf: [UInt8(0x00),UInt8(0x00),UInt8(0x00),UInt8(0x00)])
        
        return txToSign
    }
    
    private func calculateChange(
        unspents: [RadiantUnspentTransaction],
        amountSatoshi: Decimal,
        fee: Decimal
    ) -> Decimal {
        let fullAmountSatoshi = Decimal(unspents.reduce(0, {$0 + $1.amount}))
        let feeSatoshi = fee * decimalValue
        return fullAmountSatoshi - amountSatoshi - feeSatoshi
    }
    
    private func buildUnspents(with outputScripts: [Data]) -> [RadiantUnspentTransaction] {
        unspentOutputs
            .enumerated()
            .compactMap { index, txRef  in
                let hash = Data(hex: txRef.transactionHash)
                let outputScript = outputScripts.count == 1 ? outputScripts.first! : outputScripts[index]
                return RadiantUnspentTransaction(
                    amount: txRef.amount,
                    outputIndex: txRef.outputIndex,
                    hash: hash,
                    outputScript: outputScript
                )
            }
    }
    
    private func buildSignedScripts(signatures: [Data], publicKey: Data) -> [Data]? {
        var scripts: [Data] = .init()
        scripts.reserveCapacity(signatures.count)
        for signature in signatures {
            guard let signDer = try? Secp256k1Signature(with: signature).serializeDer() else {
                return nil
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
    
    private func buildOutputScript(address: String) -> Data? {
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
        
        guard let sendScript = buildOutputScript(address: targetAddress) else {
            throw WalletError.failedToBuildTx
        }
        
        outputs.append(sendScript.count.byte)
        outputs.append(contentsOf: sendScript)
        
        //output for change (if any)
        if change != 0 {
            outputs.append(contentsOf: change.bytes8LE)
            
            guard let changeOutputScriptBytes = buildOutputScript(address: sourceAddress) else {
                throw WalletError.failedToBuildTx
            }
            
            outputs.append(changeOutputScriptBytes.count.byte)
            outputs.append(contentsOf: changeOutputScriptBytes)
        }
        
        let hashOutput = outputs.sha256().sha256()
        
        // Write bytes
        txToSign.append(contentsOf: hashOutput)
    }
    
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
        
        guard let sendScript = buildOutputScript(address: targetAddress) else {
            throw WalletError.failedToBuildTx
        }
        
        // Hash of the locking script
        let scriptHash = sendScript.sha256().sha256()
        outputs.append(contentsOf: scriptHash)
        
        outputs.append(0.bytes4LE)
        
        // Add zeroRef 32 bytes
        outputs.append(contentsOf: zeroRef)
        
        //output for change (if any)
        if change != 0 {
            outputs.append(contentsOf: change.bytes8LE)
            
            guard let changeOutputScriptBytes = buildOutputScript(address: sourceAddress) else {
                throw WalletError.failedToBuildTx
            }
            
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

fileprivate struct RadiantUnspentTransaction {
    let amount: UInt64
    let outputIndex: Int
    let hash: Data
    let outputScript: Data
}
