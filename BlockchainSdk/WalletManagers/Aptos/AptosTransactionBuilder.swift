//
//  AptosTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 25.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import WalletCore
import TangemSdk
import CryptoKit

final class AptosTransactionBuilder {
    private let publicKey: Data
    private let decimalValue: Decimal
    private let chainId: AptosChainId
    
    private var coinType: CoinType { .algorand }
    
    // MARK: - Init
    
    init(
        publicKey: Data,
        decimalValue: Decimal,
        chainId: AptosChainId
    ) {
        self.publicKey = publicKey
        self.decimalValue = decimalValue
        self.chainId = chainId
    }
    
    // MARK: - Implementation

    func buildForSign(transaction: Transaction) throws -> Data {
        let input = try buildInput(transaction: transaction)
        let txInputData = try input.serializedData()

        guard !txInputData.isEmpty else {
            throw WalletError.failedToBuildTx
        }

        let preImageHashes = TransactionCompiler.preImageHashes(coinType: coinType, txInputData: txInputData)
        let preSigningOutput = try TxCompilerPreSigningOutput(serializedData: preImageHashes)

        guard preSigningOutput.error == .ok, !preSigningOutput.data.isEmpty else {
            Log.debug("AptosPreSigningOutput has a error: \(preSigningOutput.errorMessage)")
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
        
        let signingOutput = try AptosSigningOutput(serializedData: compiledTransaction)

        guard !signingOutput.encoded.isEmpty else {
            Log.debug("AptosSigningOutput has a error")
            throw WalletError.failedToBuildTx
        }

        return signingOutput.encoded
    }

    /*
     This links describe basic structure transaction Aptos Blockchain
     - https://aptos.dev/concepts/txns-states
     */
    private func buildInput(transaction: Transaction) throws -> AptosSigningInput {
        try publicKey.validateAsEdKey()
        
        let amount = (transaction.amount.value * decimalValue).roundedDecimalNumber.uint64Value
        
        let transfer = AptosTransferMessage.with {
            $0.to = transaction.destinationAddress
            $0.amount = amount
        }

        let input = AptosSigningInput.with { input in
            input.chainID = chainId.rawValue
            input.sender = transaction.sourceAddress
            input.transfer = transfer
        }
        
        return input
    }
}
