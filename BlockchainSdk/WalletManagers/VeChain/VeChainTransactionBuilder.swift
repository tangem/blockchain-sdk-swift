//
//  VeChainTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 18.12.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import WalletCore
import BigInt

final class VeChainTransactionBuilder {
    private var coinType: CoinType { .veChain }

    func buildForSign(transaction: Transaction) throws -> Data {
        guard transaction.params is VeChainTransactionParams else {
            throw WalletError.failedToBuildTx
        }

        let input = try buildInput(transaction: transaction)
        let txInputData = try input.serializedData()

        guard !txInputData.isEmpty else {
            throw WalletError.failedToBuildTx
        }

        let preImageHashes = TransactionCompiler.preImageHashes(coinType: coinType, txInputData: txInputData)
        let output = try TxCompilerPreSigningOutput(serializedData: preImageHashes)

        guard output.error == .ok else {
            throw WalletError.failedToBuildTx
        }

        return output.dataHash
    }

    func buildForSend(transaction: Transaction, signature: Data) throws -> Data {
        guard let transactionParams = transaction.params as? VeChainTransactionParams else {
            throw WalletError.failedToBuildTx
        }

        let input = try buildInput(transaction: transaction)
        let txInputData = try input.serializedData()

        guard !txInputData.isEmpty else {
            throw WalletError.failedToBuildTx
        }

        let publicKey = try Secp256k1Key(with: transactionParams.publicKey.blockchainKey).decompress()

        let compiledTransaction = TransactionCompiler.compileWithSignatures(
            coinType: coinType,
            txInputData: txInputData,
            signatures: signature.asDataVector(),
            publicKeys: publicKey.asDataVector()
        )

        let output = try VeChainSigningOutput(serializedData: compiledTransaction)

        guard output.error == .ok else {
            throw WalletError.failedToBuildTx
        }

        let serializedData = output.encoded

        guard !serializedData.isEmpty else {
            throw WalletError.failedToBuildTx
        }

        return serializedData
    }

    private func buildInput(transaction: Transaction) throws -> VeChainSigningInput {
        guard let transactionParams = transaction.params as? VeChainTransactionParams else {
            throw WalletError.failedToBuildTx
        }

        // TODO: Andrey Fedorov - Add actual implementation
        return VeChainSigningInput()
    }
}
