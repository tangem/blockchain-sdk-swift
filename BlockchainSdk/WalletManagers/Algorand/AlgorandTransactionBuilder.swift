//
//  AlgorandTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 09.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import WalletCore
import BigInt

final class AlgorandTransactionBuilder {
    private let isTestnet: Bool
    private var coinType: CoinType { .algorand }
    
    init(isTestnet: Bool) {
        self.isTestnet = isTestnet
    }
    
    // MARK: - Implementation

    func buildForSign(transaction: Transaction, with params: AlgorandTransactionParams.Build) throws -> Data {
        let input = try buildInput(transaction: transaction, buildParams: params)
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

    func buildForSend(transaction: Transaction, buildParams: AlgorandTransactionParams.Build, signature: Data) throws -> Data {
        let input = try buildInput(transaction: transaction, buildParams: buildParams)
        let txInputData = try input.serializedData()

        guard !txInputData.isEmpty else {
            throw WalletError.failedToBuildTx
        }

        let compiledTransaction = TransactionCompiler.compileWithSignatures(
            coinType: coinType,
            txInputData: txInputData,
            signatures: signature.asDataVector(),
            publicKeys: buildParams.publicKey.blockchainKey.asDataVector()
        )
        let output = try AlgorandSigningOutput(serializedData: compiledTransaction)

        guard output.error == .ok else {
            throw WalletError.failedToBuildTx
        }

        let serializedData = try output.serializedData()

        guard !serializedData.isEmpty else {
            throw WalletError.failedToBuildTx
        }

        return serializedData
    }

    /*
     This links describe basic structure of pay type transaction Algorand Blockchain
     - https://developer.algorand.org/docs/get-details/transactions/
     - https://developer.algorand.org/docs/get-details/transactions/#genesis-hash
     - https://developer.algorand.org/docs/get-details/transactions/transactions/#common-fields-header-and-type
     */
    private func buildInput(transaction: Transaction, buildParams: AlgorandTransactionParams.Build) throws -> AlgorandSigningInput {
        let transfer = AlgorandTransfer.with {
            $0.toAddress = transaction.destinationAddress
            $0.amount = (transaction.amount.value * Blockchain.algorand(testnet: isTestnet).decimalValue).roundedDecimalNumber.uint64Value
        }

        return try AlgorandSigningInput.with { input in
            input.publicKey = buildParams.publicKey.blockchainKey
            input.genesisID = isTestnet ? GenesisChallenge.testnet : GenesisChallenge.mainnet
            input.genesisHash = try GenesisChallenge.genesisHash(isTestnet: isTestnet)
            input.fee = (transaction.fee.amount.value * Blockchain.algorand(testnet: isTestnet).decimalValue).roundedDecimalNumber.uint64Value
            input.firstRound = buildParams.round
            input.lastRound = buildParams.round + 1000
            input.transfer = transfer
        }
    }
}

extension AlgorandTransactionBuilder {
    enum GenesisChallenge {
        static let mainnet = "mainnet-v1.0"
        static let testnet = "testnet-v1.0"
        static let mainnetGenesisHash = "wGHE2Pwdvd7S12BL5FaOP20EGYesN73ktiC1qzkkit8="
        static let testnetGenesisHash = "SGO1GKSzyE7IEPItTxCByw9x8FmnrCDexi9/cOUJOiI="
        
        static func genesisHash(isTestnet: Bool) throws -> Data {
            let genesisHashValue = isTestnet ? testnetGenesisHash : mainnetGenesisHash
            
            guard let genesisHashData = genesisHashValue.data(using: .utf8) else {
                throw WalletError.failedToBuildTx
            }
            
            return genesisHashData
        }
    }
}
