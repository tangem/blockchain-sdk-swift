//
//  KaspaTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 15.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import HDWalletKit

class KaspaTransactionBuilder {
    var unspentOutputs: [BitcoinUnspentOutput] = []
    
    let blockchain: Blockchain
    
    init(blockchain: Blockchain) {
        self.blockchain = blockchain
    }
    
    func unspentOutputs(for amount: Amount) -> Int {
        return unspentOutputs.count
    }
    
    func scriptPublicKey(address: String) -> Data? {
        guard let components = KaspaAddressComponents(address) else { return nil }
        
        let prefix: UInt8 = OpCode.OP_HASH256.value
        let suffix: UInt8
        switch components.type {
        case .P2PK_Schnorr:
            suffix = OpCode.OP_CHECKSIG.value
        case .P2PK_ECDSA:
            suffix = OpCode.OP_CODESEPARATOR.value
        case .P2SH:
            
            suffix = OpCode.OP_EQUAL.value
        default:
            return nil
        }
        
//        let OP_CHECKSIG: UInt8 = 0xAC
//        let key = components.hash + Data(OP_CHECKSIG)
        let size = UInt8(components.hash.count)
        return Data(prefix) + size.data + components.hash + Data(suffix)
        return Data()
    }
    
    func buildForSign(_ transaction: Transaction) -> (KaspaTransaction, [Data])? {
        guard
            let sourceAddressScript = scriptPublicKey(address: transaction.sourceAddress)?.hex,
            let destinationAddressScript = scriptPublicKey(address: transaction.destinationAddress)?.hex
        else {
            return nil
        }
              
        print("p2sh", scriptPublicKey(address: "kaspa:pqurku73qluhxrmvyj799yeyptpmsflpnc8pha80z6zjh6efwg3v2rrepjm5r")!.hex)
        print("src", scriptPublicKey(address: transaction.sourceAddress)!.hex)
        print("dst", scriptPublicKey(address: transaction.destinationAddress)!.hex)
        
        var outputs: [KaspaOutput] = [
            KaspaOutput(
                amount: amount(from: transaction),
                scriptPublicKey: KaspaScriptPublicKey(
                    scriptPublicKey: "2060072BBDDB7A7D1DBF40302CE04D51DB49E223F8E5159FCCE14143FD4BE20328AC",
                    version: 0
                )
            )
        ]
        
        if let change = change(transaction, unspentOutputs: unspentOutputs) {
            outputs.append(
                KaspaOutput(
                    amount: change,
                    scriptPublicKey: KaspaScriptPublicKey(
                        scriptPublicKey: "2103EB30400CE9D1DEED12B84D4161A1FA922EF4185A155EF3EC208078B3807B126FAB",
                        version: 0
                    )
                )
            )
        }
        
        
        let inputs = unspentOutputs
        let kaspaTransaction = KaspaTransaction(inputs: inputs, outputs: outputs)
        
        var hashes: [Data] = []
        for (index, unspentOutput) in unspentOutputs.enumerated() {
            print(unspentOutput)
            
            let value = unspentOutput.amount
            
            let z = kaspaTransaction.hashForSignatureWitness(
                inputIndex: index,
                connectedScript: Data(hexString: unspentOutput.outputScript),
                prevValue: value
            )
            
            print("hash for signature witness")
            print(z.hex)
            
            hashes.append(z)
        }
        
        
        
        return (kaspaTransaction, hashes)
    }
    
    func buildForSend(transaction builtTransaction: KaspaTransaction, signatures: [Data]) -> KaspaTransactionData {
        let inputs = builtTransaction.inputs.enumerated().map { (index, input) in
            let sigHashAllSuffix: UInt8 = 1
            let script = signatures[index] + sigHashAllSuffix.data
            let size = UInt8(script.count)
            
            let newSignatureScript = (size.data + script).hexadecimal
            let outpoint = KaspaPreviousOutpoint(transactionId: input.transactionHash, index: input.outputIndex)
            let newInput = KaspaInput(previousOutpoint: outpoint, signatureScript: newSignatureScript)
            return newInput
        }
        
        return KaspaTransactionData(inputs: inputs, outputs: builtTransaction.outputs)
    }
    
    private func amount(from transaction: Transaction) -> UInt64 {
        return ((transaction.amount.value * blockchain.decimalValue) as NSDecimalNumber).uint64Value
    }
    
    private func change(_ transaction: Transaction, unspentOutputs: [BitcoinUnspentOutput]) -> UInt64? {
        let fullAmount = unspentOutputs.map { $0.amount }.reduce(0, +)
        let transactionAmount = ((transaction.amount.value * blockchain.decimalValue).rounded() as NSDecimalNumber).uint64Value
        let feeAmount = ((transaction.fee.value * blockchain.decimalValue).rounded() as NSDecimalNumber).uint64Value
        
        let change = fullAmount - transactionAmount - feeAmount
        return change == 0 ? nil : change
    }
}

fileprivate extension Transaction {
    //    func toKaspaTransaction(unspentOutputs: [BitcoinUnspentOutput], change: Amount) -> KaspaTransaction {
    
    //    }
    
}
