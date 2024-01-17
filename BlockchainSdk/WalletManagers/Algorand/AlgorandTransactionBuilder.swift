//
//  AlgorandTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 09.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import WalletCore
import TangemSdk
import CryptoKit

final class AlgorandTransactionBuilder {
    private let publicKey: Data
    private let isTestnet: Bool
    private var coinType: CoinType { .algorand }
    
    private var decimalValue: Decimal {
        Blockchain.algorand(testnet: isTestnet).decimalValue
    }
    
    // MARK: - Init
    
    init(publicKey: Data, isTestnet: Bool) {
        self.publicKey = publicKey
        self.isTestnet = isTestnet
    }
    
    // MARK: - Implementation

    func buildForSign(transaction: Transaction, with params: AlgorandBuildParams) throws -> Data {
        let input = try buildInput(transaction: transaction, buildParams: params)
        let txInputData = try input.serializedData()

        guard !txInputData.isEmpty else {
            throw WalletError.failedToBuildTx
        }

        let preImageHashes = TransactionCompiler.preImageHashes(coinType: coinType, txInputData: txInputData)
        let preSigningOutput = try TxCompilerPreSigningOutput(serializedData: preImageHashes)

        guard preSigningOutput.error == .ok, !preSigningOutput.data.isEmpty else {
            Log.debug("AlgorandPreSigningOutput has a error: \(preSigningOutput.errorMessage)")
            throw WalletError.failedToBuildTx
        }

        return preSigningOutput.data
    }

    func buildForSend(transaction: Transaction, with params: AlgorandBuildParams, signature: Data) throws -> Data {
        let input = try buildInput(transaction: transaction, buildParams: params)
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
            Log.debug("AlgorandSigningOutput has a error: \(signingOutput.errorMessage)")
            throw WalletError.failedToBuildTx
        }

        return signingOutput.encoded
    }

    /*
     This links describe basic structure of pay type transaction Algorand Blockchain
     - https://developer.algorand.org/docs/get-details/transactions/
     - https://developer.algorand.org/docs/get-details/transactions/#genesis-hash
     - https://developer.algorand.org/docs/get-details/transactions/transactions/#common-fields-header-and-type
     */
    private func buildInput(transaction: Transaction, buildParams: AlgorandBuildParams) throws -> AlgorandSigningInput {
        do {
            try publicKey.validateAsEdKey()
        } catch {
            throw WalletError.failedToBuildTx
        }
        
        let transfer = AlgorandTransfer.with {
            $0.toAddress = transaction.destinationAddress
            $0.amount = (transaction.amount.value * decimalValue).roundedDecimalNumber.uint64Value
        }

        let input = AlgorandSigningInput.with { input in
            input.publicKey = publicKey
            input.genesisID = buildParams.genesisId
            input.genesisHash = Data(base64Encoded: buildParams.genesisHash) ?? Data()
            input.note = buildParams.nonce?.data(using: .utf8) ?? Data()
            input.firstRound = buildParams.firstRound
            input.lastRound = buildParams.lastRound
            input.fee = (transaction.fee.amount.value * decimalValue).roundedDecimalNumber.uint64Value
            input.transfer = transfer
        }
        
        return input
    }
    
    // TODO: - Use for assembly asset algorand transaction write this
    private func buildAssetInput(transaction: Transaction, buildParams: AlgorandBuildParams) throws -> AlgorandSigningInput {
        throw WalletError.failedToBuildTx
    }
}
