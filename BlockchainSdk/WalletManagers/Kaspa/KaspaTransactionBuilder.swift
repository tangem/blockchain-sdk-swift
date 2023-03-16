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
    
    func buildForSign(_ transaction: Transaction) -> [Data] {
//        print(unspentOutputs)
//        print(transaction.destinationAddress)
//        print(transaction.amount)
        
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
        
        let kaspaTransaction = KaspaTransaction(inputs: unspentOutputs, outputs: outputs)
        
//        let connectedScript =
        
//        if let unspentOutput = unspentOutputs.first {
        
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
        
//        let kaspaTransaction = transaction
        
        
        return hashes
    }
    
    func buildForSend(_ transaction: Transaction) {
        
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
