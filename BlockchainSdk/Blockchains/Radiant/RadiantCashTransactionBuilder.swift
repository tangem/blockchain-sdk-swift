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
    
    var unspentOutputs: [BitcoinUnspentOutput]?
    
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
        
        guard let unspents = buildUnspents(with: [outputScript]) else {
            throw "RadiantCashTransactionBuilder empty unspents"
        }
        
        let amountSatoshi = transaction.amount.value  * decimalValue
        let changeSatoshi = calculateChange(unspents: unspents, amount: transaction.amount.value , fee: transaction.fee.amount.value)
        
        var hashes = [Data]()
        
        for index in 0..<unspents.count {
            guard let tx = buildPreimage(unspents: unspents,
                                         amount: amountSatoshi,
                                         change: changeSatoshi,
                                         targetAddress: transaction.destinationAddress,
                                         sourceAddress: transaction.sourceAddress,
                                         index: index) else {
                throw "RadiantCashTransactionBuilder failed build preimage"
            }
            // tx.append(contentsOf: [UInt8(0x01),UInt8(0x00),UInt8(0x00),UInt8(0x00)]) for btc
            let hash = tx.sha256().sha256()
            hashes.append(hash)
        }
        
        return hashes
    }
    
    public func buildForSend(transaction: Transaction, signatures: [Data]) throws -> Data {
        guard unspentOutputs != nil else {
            throw "RadiantCashTransactionBuilder empty unspents"
        }
        
        guard 
            let outputScripts = buildSignedScripts(signatures: signatures, publicKey: walletPublicKey),
            let unspents = buildUnspents(with: outputScripts) else {
            throw "RadiantCashTransactionBuilder empty unspents"
        }
        
        let amountSatoshi = transaction.amount.value  * decimalValue
        let changeSatoshi = calculateChange(unspents: unspents, amount: transaction.amount.value, fee: transaction.fee.amount.value )
        
        let tx = buildTxBody(unspents: unspents,
                             amount: amountSatoshi,
                             change: changeSatoshi,
                             targetAddress: transaction.destinationAddress,
                             changeAddress: transaction.sourceAddress,
                             index: nil)
        
        guard let tx else {
            throw "RadiantCashTransactionBuilder empty tx"
        }
        
        print(tx.hexString)
        
        return tx
    }
    
    private func calculateChange(unspents: [UnspentTransaction], amount: Decimal, fee: Decimal) -> Decimal {
        let fullAmountSatoshi = Decimal(unspents.reduce(0, {$0 + $1.amount}))
        let feeSatoshi = fee * decimalValue
        let amountSatoshi = amount * decimalValue
        return fullAmountSatoshi - amountSatoshi - feeSatoshi
    }
    
    private func buildUnspents(with outputScripts:[Data]) -> [UnspentTransaction]? {
        let unspentTransactions: [UnspentTransaction]? = unspentOutputs?.enumerated().compactMap({ index, txRef  in
            let hash = Data(hex: txRef.transactionHash)
            let outputScript = outputScripts.count == 1 ? outputScripts.first! : outputScripts[index]
            return UnspentTransaction(amount: txRef.amount, outputIndex: txRef.outputIndex, hash: hash, outputScript: outputScript)
        })
        
        return unspentTransactions
    }
    
    private func buildPreimage(
        unspents: [UnspentTransaction],
        amount: Decimal,
        change: Decimal,
        targetAddress: String,
        sourceAddress: String,
        index: Int
    ) throws -> Data {
        
        var txToSign = Data()
        
        // version
        txToSign.append(contentsOf: [UInt8(0x02),UInt8(0x00),UInt8(0x00),UInt8(0x00)])
        //txToSign.append(contentsOf: [UInt8(0x01),UInt8(0x00),UInt8(0x00),UInt8(0x00)]) for btc

        //hashPrevouts (32-byte hash)
        getPrevoutHash(unspents, into: &txToSign)
        
        //hashSequence (32-byte hash), ffffffff only
        getSequenceHash(unspents, into: &txToSign)
        
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
        
        //hashOutputs (32-byte hash)
        let hashOutputs = try getHashOutputs(
            amount: amount,
            sourceAddress: sourceAddress,
            targetAddress: targetAddress,
            change: change
        )
        
        txToSign.append(contentsOf: hashOutputs)
        
        //nLocktime of the transaction (4-byte little endian)
        txToSign.append(contentsOf: [UInt8(0x00),UInt8(0x00),UInt8(0x00),UInt8(0x00)])
        
        //sighash type of the signature (4-byte little endian)
        txToSign.append(contentsOf: [UInt8(0x41),UInt8(0x00),UInt8(0x00),UInt8(0x00)])
        
        return txToSign
    }
    
    private func buildTxBody(unspents: [UnspentTransaction],
                             amount: Decimal,
                             change: Decimal,
                             targetAddress: String,
                             changeAddress: String,
                             index: Int?) -> Data? {
        var txToSign = Data()
        // version
        txToSign.append(contentsOf: [UInt8(0x02),UInt8(0x00),UInt8(0x00),UInt8(0x00)])
        //txToSign.append(contentsOf: [UInt8(0x01),UInt8(0x00),UInt8(0x00),UInt8(0x00)]) for btc
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
            return nil
        }
        //hex str 1976a914....88ac
        txToSign.append(outputScriptBytes.count.byte)
        txToSign.append(contentsOf: outputScriptBytes)
        
        if change != 0 {
            //8 bytes
            txToSign.append(contentsOf: change.bytes8LE)
            //hex str 1976a914....88ac
            guard let outputScriptChangeBytes = buildOutputScript(address: changeAddress) else {
                return nil
            }
            txToSign.append(outputScriptChangeBytes.count.byte)
            txToSign.append(contentsOf: outputScriptChangeBytes)
        }
        //00000000
        txToSign.append(contentsOf: [UInt8(0x00),UInt8(0x00),UInt8(0x00),UInt8(0x00)])
        
        return txToSign
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
    
    private func getPrevoutHash(_ unspents: [UnspentTransaction], into txToSign: inout Data) {
        let prevouts = Data(unspents.map { Data($0.hash.reversed()) + $0.outputIndex.bytes4LE }
            .joined())
        let hashPrevouts = prevouts.sha256().sha256()
        txToSign.append(contentsOf: hashPrevouts)
    }
    
    private func getSequenceHash(_ unspents: [UnspentTransaction], into txToSign: inout Data) {
        let sequence = Data(repeating: UInt8(0xFF), count: 4 * unspents.count)
        let hashSequence = sequence.sha256().sha256()
        txToSign.append(contentsOf: hashSequence)
    }
    
    private func getHashOutputs(
        amount: Decimal,
        sourceAddress: String,
        targetAddress: String,
        change: Decimal
    ) throws -> Data {
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
            
            guard let outputScriptChangeBytes = buildOutputScript(address: sourceAddress) else {
                throw WalletError.failedToBuildTx
            }
            
            outputs.append(outputScriptChangeBytes.count.byte)
            outputs.append(contentsOf: outputScriptChangeBytes)
        }
        
        return outputs.sha256().sha256()
    }
    
    private func getHashOutputHashes() {
        var outputHashes = Data()
    }
}

struct UnspentTransaction {
    let amount: UInt64
    let outputIndex: Int
    let hash: Data
    let outputScript: Data
}

/*
 
 // Add hashOutputHashes specify for Radiant
 var outputHashes = Data()
 
 //hashOutputs (32-byte hash)
 var outputs = Data()
 
 outputs.append(contentsOf: amount.bytes8LE)
 outputHashes.append(contentsOf: amount.bytes8LE)
 
 guard let sendScript = buildOutputScript(address: targetAddress) else {
     return nil
 }
 
 outputs.append(sendScript.count.byte)
 
 outputs.append(contentsOf: sendScript)
 outputHashes.append(contentsOf: sendScript.getDoubleSha256())
 
 // TODO: - In function count refs for smart contracts (total refs)
 outputHashes.append(0.bytes8LE)

 // TODO: - In function count refs for smart contracts (total refs)
 for _ in 0..<32 {
     outputHashes.append(0.byte)
 }
 
 //output for change (if any)
 if change != 0 {
     outputs.append(contentsOf: change.bytes8LE)
     outputHashes.append(contentsOf: change.bytes8LE)
     
     guard let outputScriptChangeBytes = buildOutputScript(address: sourceAddress) else {
         return nil
     }
     
     outputs.append(outputScriptChangeBytes.count.byte)
     outputs.append(contentsOf: outputScriptChangeBytes)
     
     outputHashes.append(contentsOf: outputScriptChangeBytes.getDoubleSha256())
     
     // TODO: - In function count refs for smart contracts (total refs)
     outputHashes.append(0.bytes8LE)

     // TODO: - In function count refs for smart contracts (total refs)
     for _ in 0..<32 {
         outputHashes.append(0.byte)
     }
 }
 
 let hashOutputHashes = outputHashes.getDoubleSha256()
 txToSign.append(contentsOf: hashOutputHashes)
 
 let hashOutputs = outputs.getDoubleSha256()
 txToSign.append(contentsOf: hashOutputs)
 
 //nLocktime of the transaction (4-byte little endian)
 txToSign.append(contentsOf: [UInt8(0x00),UInt8(0x00),UInt8(0x00),UInt8(0x00)])
 
 //sighash type of the signature (4-byte little endian)
 txToSign.append(contentsOf: [UInt8(0x41),UInt8(0x00),UInt8(0x00),UInt8(0x00)])
 
 return txToSign
 
 */
