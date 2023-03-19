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
    private var unspentOutputs: [BitcoinUnspentOutput] = []
    
    private let blockchain: Blockchain
    private let maxInputCount = 84
    
    init(blockchain: Blockchain) {
        self.blockchain = blockchain
    }
    
    func unspentOutputs(for amount: Amount) -> Int {
        return unspentOutputs.count
    }
    
    func setUnspentOutputs(_ unspentOutputs: [BitcoinUnspentOutput]) {
        let sortedOutputs = unspentOutputs.sorted {
            $0.amount > $1.amount
        }
        
        self.unspentOutputs = Array(sortedOutputs.prefix(maxInputCount))
    }
    
    func scriptPublicKey(address: String) throws -> Data {
        guard
            let addressService = blockchain.getAddressService() as? KaspaAddressService,
            let components = addressService.parse(address)
        else {
            throw WalletError.failedToBuildTx
        }
        
        let prefix: UInt8?
        let suffix: UInt8
        switch components.type {
        case .P2PK_Schnorr:
            prefix = nil
            suffix = OpCode.OP_CHECKSIG.value
        case .P2PK_ECDSA:
            prefix = nil
            suffix = OpCode.OP_CODESEPARATOR.value
        case .P2SH:
            prefix = OpCode.OP_HASH256.value
            suffix = OpCode.OP_EQUAL.value
        }
        
//        let OP_CHECKSIG: UInt8 = 0xAC
//        let key = components.hash + Data(OP_CHECKSIG)
        let size = UInt8(components.hash.count)
        let prefixData: Data
        if let prefix {
            prefixData = prefix.data
        } else {
            prefixData = Data()
        }
        let suffixData = suffix.data
        return prefixData + size.data + components.hash + suffixData
    }
    
    func buildForSign(_ transaction: Transaction) throws -> (KaspaTransaction, [Data]) {
        let sourceAddressScript = try scriptPublicKey(address: transaction.sourceAddress).hex
        let destinationAddressScript = try scriptPublicKey(address: transaction.destinationAddress).hex
        
        var outputs: [KaspaOutput] = [
            KaspaOutput(
                amount: amount(from: transaction),
                scriptPublicKey: KaspaScriptPublicKey(
                    scriptPublicKey: destinationAddressScript,
                    version: 0
                )
            )
        ]
        
        if let change = change(transaction, unspentOutputs: unspentOutputs) {
            outputs.append(
                KaspaOutput(
                    amount: change,
                    scriptPublicKey: KaspaScriptPublicKey(
                        scriptPublicKey: sourceAddressScript,
                        version: 0
                    )
                )
            )
        }
        
        
        let inputs = unspentOutputs
        let availableInputSatoshiValue = inputs.reduce(0) { $0 + $1.amount }
        let availableInputValue = Amount(with: blockchain, value: Decimal(availableInputSatoshiValue) / blockchain.decimalValue)
        
        guard availableInputValue >= transaction.amount else {
            throw WalletError.failedToBuildTx
        }
        
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
