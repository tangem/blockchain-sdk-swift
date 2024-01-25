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
    private let isTestnet: Bool
    private let decimalValue: Decimal
    
    private var coinType: CoinType { .algorand }
    
    // MARK: - Init
    
    init(publicKey: Data, isTestnet: Bool, decimalValue: Decimal) {
        self.publicKey = publicKey
        self.isTestnet = isTestnet
        self.decimalValue = decimalValue
    }
    
    // MARK: - Implementation

    func buildForSign(transaction: Transaction, with params: AptosBuildParams) throws -> Data {
        let input = try buildInput(transaction: transaction, buildParams: params)
        let txInputData = try input.serializedData()

        guard !txInputData.isEmpty else {
            throw WalletError.failedToBuildTx
        }

        let preImageHashes = TransactionCompiler.preImageHashes(coinType: coinType, txInputData: txInputData)
        let preSigningOutput = try TxCompilerPreSigningOutput(serializedData: preImageHashes)

        guard preSigningOutput.error.rawValue == 0, !preSigningOutput.dataHash.isEmpty else {
            Log.debug("AptosPreSigningOutput has a error: \(preSigningOutput.errorMessage)")
            throw WalletError.failedToBuildTx
        }

        return preSigningOutput.dataHash
    }

    func buildForSend(transaction: Transaction, with params: AptosBuildParams, signature: Data) throws -> Data {
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
    private func buildInput(transaction: Transaction, buildParams: AptosBuildParams) throws -> AptosSigningInput {
        do {
            try publicKey.validateAsEdKey()
        } catch {
            throw WalletError.failedToBuildTx
        }
        
        let transfer = AptosTransferMessage.with {
            $0.to = transaction.destinationAddress
            $0.amount = (transaction.amount.value * decimalValue).roundedDecimalNumber.uint64Value
        }

        let input = AptosSigningInput.with { input in
            input.chainID = buildParams.chainId
            input.sender = transaction.sourceAddress
            input.sequenceNumber = buildParams.sequenceNumber
            input.expirationTimestampSecs = buildParams.expirationTimestampSecs
            input.transfer = transfer
        }
        
        return input
    }
    
    // TODO: - Use for assembly asset algorand transaction write this
    private func buildAssetInput(transaction: Transaction, buildParams: AptosBuildParams) throws -> AptosSigningInput {
        throw WalletError.failedToBuildTx
    }
}
