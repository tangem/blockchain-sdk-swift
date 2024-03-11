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

    func buildForSign(transaction: Transaction) throws -> [WalletCore.TW_Bitcoin_Proto_HashPublicKey] {
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
        
        return preSigningOutput.hashPublicKeys
    }

    func buildForSend(transaction: Transaction, signatures: [SignatureInfo]) throws -> Data {
        let input = try buildInput(transaction: transaction)
        let txInputData = try input.serializedData()

        guard !txInputData.isEmpty else {
            throw WalletError.failedToBuildTx
        }
        
        let preImageHashes = TransactionCompiler.preImageHashes(coinType: coinType, txInputData: txInputData)
        
        let signaturesVector = DataVector()
        let publicKeysVector = DataVector()
        
        try signatures.forEach { info in
            guard PublicKey(data: info.publicKey, type: .secp256k1)?.verify(signature: info.signature, message: preImageHashes) ?? false else {
                throw WalletError.failedToBuildTx
            }
            
            signaturesVector.add(data: info.signature)
            publicKeysVector.add(data: info.publicKey)
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
            try buildUnspent(transaction: $0)
        }
        
        let amount = (transaction.amount.value * decimalValue).roundedDecimalNumber.int64Value
        let byteFee = (transaction.fee.amount.value * decimalValue).roundedDecimalNumber.int64Value
        
        let input = BitcoinSigningInput.with {
            $0.hashType = WalletCore.BitcoinScript.hashTypeForCoin(coinType: coinType)
            $0.amount = amount
            $0.byteFee = byteFee
            $0.useMaxAmount = false
            $0.coinType = coinType.rawValue
            $0.toAddress = transaction.destinationAddress
            $0.changeAddress = transaction.changeAddress
            $0.utxo = unspentTransactions
        }
        
        return input
    }
    
    private func buildUnspent(transaction: BitcoinUnspentOutput) throws -> BitcoinUnspentTransaction {
        BitcoinUnspentTransaction.with {
            $0.amount = Decimal(transaction.amount).int64Value
            $0.outPoint.index = UInt32(transaction.outputIndex)
            $0.outPoint.hash = Data.reverse(hexString: transaction.transactionHash)
            $0.outPoint.sequence = UInt32.max
            $0.script = Data(hexString: transaction.outputScript)
        }
    }
}

// MARK: - Error

extension RadiantTransactionBuilder {
    enum Error: Swift.Error {}
}
