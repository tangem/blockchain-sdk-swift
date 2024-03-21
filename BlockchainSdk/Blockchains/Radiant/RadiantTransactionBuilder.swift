//
//  RadiantTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 05.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import WalletCore

final class RadiantTransactionBuilder {
    private let coinType: CoinType
    private let publicKey: Data
    private let walletAddress: String
    private let decimalValue: Decimal
    
    private var unspents: [BitcoinUnspentOutput] = []
    
    // MARK: - Init
    
    init(
        coinType: CoinType,
        publicKey: Data,
        decimalValue: Decimal,
        walletAddress: String
    ) {
        self.coinType = coinType
        self.publicKey = publicKey
        self.decimalValue = decimalValue
        self.walletAddress = walletAddress
    }
    
    // MARK: - Implementation
    
    func update(unspents: [BitcoinUnspentOutput]) {
        self.unspents = unspents
    }

    func buildForSign(transaction: Transaction) throws -> [Data] {
        let input = try buildInput(transaction: transaction)
        let txInputData = try input.serializedData()

        guard !txInputData.isEmpty else {
            throw WalletError.failedToBuildTx
        }

        let preImageHashes = TransactionCompiler.preImageHashes(coinType: coinType, txInputData: txInputData)
        let preSigningOutput = try BitcoinPreSigningOutput(serializedData: preImageHashes)

        guard preSigningOutput.error == .ok, !preSigningOutput.hashPublicKeys.isEmpty else {
            Log.debug("RadiantPreSigningOutput has a error: \(preSigningOutput.errorMessage)")
            throw WalletError.failedToBuildTx
        }
        
        return preSigningOutput.hashPublicKeys.map { $0.dataHash }
    }

    func buildForSend(transaction: Transaction, signatures: [Data]) throws -> Data {
        let input = try buildInput(transaction: transaction)
        let txInputData = try input.serializedData()

        guard !txInputData.isEmpty else {
            throw WalletError.failedToBuildTx
        }
        
        let signaturesVector = DataVector()
        let publicKeysVector = DataVector()
        
        let derSignatures = try convertToDER(signatures)
        
        derSignatures.forEach { signature in
            signaturesVector.add(data: signature)
            publicKeysVector.add(data: publicKey)
        }

        let compiledTransaction = TransactionCompiler.compileWithSignatures(
            coinType: coinType,
            txInputData: txInputData,
            signatures: signaturesVector,
            publicKeys: publicKeysVector
        )
        
        let signingOutput = try BitcoinSigningOutput(serializedData: compiledTransaction)

        guard signingOutput.error == .ok, !signingOutput.encoded.isEmpty else {
            Log.debug("RadiantPreSigningOutput has a error: \(signingOutput.errorMessage)")
            throw WalletError.failedToBuildTx
        }
        
        print("HEX: \(signingOutput.encoded.hexadecimal)")

        return signingOutput.encoded
    }
    
    // MARK: - Private Implementation

    private func buildInput(transaction: Transaction) throws -> BitcoinSigningInput {
        do {
            try publicKey.validateAsSecp256k1Key()
        } catch {
            throw WalletError.failedToBuildTx
        }
        
        let unspentTransactions = try unspents.map {
            try buildUnspent(output: $0)
        }
        
        let amount = (transaction.amount.value * decimalValue).roundedDecimalNumber.int64Value
        let byteFee = (transaction.fee.amount.value * decimalValue).roundedDecimalNumber.int64Value
        
        let input = BitcoinSigningInput.with {
            $0.coinType = coinType.rawValue
            $0.hashType = 65
            $0.amount = amount
            $0.byteFee = 10000
            $0.useMaxAmount = false
            $0.toAddress = transaction.destinationAddress
            $0.changeAddress = transaction.changeAddress
            $0.utxo = unspentTransactions
        }
        
        return input
    }
    
    private func buildUnspent(output: BitcoinUnspentOutput) throws -> BitcoinUnspentTransaction {
        BitcoinUnspentTransaction.with {
            $0.amount = Decimal(output.amount).int64Value
            $0.outPoint.index = UInt32(output.outputIndex)
            $0.outPoint.hash = Data.reverse(hexString: output.transactionHash)
            $0.outPoint.sequence = UInt32.max
            $0.script = Data(hexString: output.outputScript)
        }
    }
    
    private func convertToDER(_ signatures: [Data]) throws -> [Data] {
        var derSigs = [Data]()
        
        let utils = Secp256k1Utils()
        
        for signature in signatures {
            let signDer = try utils.serializeDer(signature)
            derSigs.append(signDer)
        }
    
        return derSigs
    }
}

// MARK: - Error

extension RadiantTransactionBuilder {
    enum Error: Swift.Error {}
}
