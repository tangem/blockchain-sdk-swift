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

    func buildForSign(transaction: Transaction) throws -> Data {
        let input = try buildInput(transaction: transaction)
        let txInputData = try input.serializedData()

        guard !txInputData.isEmpty else {
            throw WalletError.failedToBuildTx
        }

        let preImageHashes = TransactionCompiler.preImageHashes(coinType: coinType, txInputData: txInputData)
        let preSigningOutput = try TxCompilerPreSigningOutput(serializedData: preImageHashes)

        guard preSigningOutput.error == .ok, !preSigningOutput.data.isEmpty else {
            Log.debug("RadiantPreSigningOutput has a error: \(preSigningOutput.errorMessage)")
            throw WalletError.failedToBuildTx
        }

        return preSigningOutput.data
    }

    func buildForSend(transaction: Transaction, signature: Data) throws -> Data {
        let input = try buildInput(transaction: transaction)
        let txInputData = try input.serializedData()

        guard !txInputData.isEmpty else {
            throw WalletError.failedToBuildTx
        }

        let compiledTransaction = TransactionCompiler.compileWithSignatures(
            coinType: coinType,
            txInputData: txInputData,
            signatures: signature.asDataVector(),
            publicKeys: publicKey.asDataVector()
        )
        
        let signingOutput = try AlgorandSigningOutput(serializedData: compiledTransaction)

        guard signingOutput.error == .ok, !signingOutput.encoded.isEmpty else {
            Log.debug("RadiantPreSigningOutput has a error: \(signingOutput.errorMessage)")
            throw WalletError.failedToBuildTx
        }

        return signingOutput.encoded
    }
    
    // MARK: - Private Implementation

    private func buildInput(transaction: Transaction) throws -> BitcoinSigningInput {
        let unspentTransactions = try unspents.map {
            try buildUnspent(transaction: $0)
        }
        
        let amount = transaction.amount.value.int64Value
        
        let input = BitcoinSigningInput.with {
            $0.hashType = WalletCore.BitcoinScript.hashTypeForCoin(coinType: coinType)
            $0.amount = amount
            $0.byteFee = 1
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
            $0.script = WalletCore.BitcoinScript.lockScriptForAddress(address: "", coin: coinType).data
        }
    }
}
