//
//  KaspaTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 15.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

class KaspaTransactionBuilder {
    var unspentOutputs: [BitcoinUnspentOutput] = []
    
    let blockchain: Blockchain
    
    init(blockchain: Blockchain) {
        self.blockchain = blockchain
    }
    
    func buildForSign(_ transaction: Transaction) -> (KaspaTransaction, [Data]) {
        let outputs: [KaspaOutput] = [
            KaspaOutput(
                amount: 100000,
                scriptPublicKey: KaspaScriptPublicKey(scriptPublicKey: "2060072BBDDB7A7D1DBF40302CE04D51DB49E223F8E5159FCCE14143FD4BE20328AC", version: 0)
            ),
            KaspaOutput(
                amount: 519870000,
                scriptPublicKey: KaspaScriptPublicKey(
                    scriptPublicKey: "2103EB30400CE9D1DEED12B84D4161A1FA922EF4185A155EF3EC208078B3807B126FAB",
                    version: 0
                )
            )
        ]
        
        let inputs = unspentOutputs
        let kaspaTransaction = KaspaTransaction(inputs: inputs, outputs: outputs)
        
        //        let connectedScript =
        
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
        
        let change = calculateChange(transaction: transaction, unspentOutputs: unspentOutputs)
        
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
    
    private func calculateChange(transaction: Transaction, unspentOutputs: [BitcoinUnspentOutput]) -> Amount {
        let fullAmountInSatoshi = unspentOutputs.map { $0.amount }.reduce(0, +)
        let fullAmount = Amount(with: blockchain, value: Decimal(fullAmountInSatoshi) / blockchain.decimalValue)
        return fullAmount - transaction.amount - transaction.fee
    }
}

fileprivate extension Transaction {
    //    func toKaspaTransaction(unspentOutputs: [BitcoinUnspentOutput], change: Amount) -> KaspaTransaction {
    
    //    }
    
}
