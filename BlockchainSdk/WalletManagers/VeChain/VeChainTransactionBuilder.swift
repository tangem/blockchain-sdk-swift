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
    private let blockchain: Blockchain

    private var coinType: CoinType { .veChain }

    /// The last byte of the genesis block ID which is used to identify a blockchain to prevent the cross-chain replay attack.
    /// Mainnet: https://explore.vechain.org/blocks/0x00000000851caf3cfdb6e899cf5958bfb1ac3413d346d43539627e6be7ec1b4a
    /// Testnet: https://explore-testnet.vechain.org/blocks/0x000000000b2bce3c70bc649a02749e8687721b09ed2e15997f466536b20bb127
    private var chainTag: Int {
        return blockchain.isTestnet ? 0x27 : 0x4a
    }

    init(blockchain: Blockchain) {
        self.blockchain = blockchain
    }

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

    func buildForSend(transaction: Transaction, hash: Data, signature: Data) throws -> Data {
        guard let transactionParams = transaction.params as? VeChainTransactionParams else {
            throw WalletError.failedToBuildTx
        }

        let input = try buildInput(transaction: transaction)
        let txInputData = try input.serializedData()

        guard !txInputData.isEmpty else {
            throw WalletError.failedToBuildTx
        }

        let publicKey = try Secp256k1Key(with: transactionParams.publicKey.blockchainKey).decompress()
        let unmarshalledSignature = try unmarshalledSignature(from: signature, publicKey: publicKey, hash: hash)

        let compiledTransaction = TransactionCompiler.compileWithSignatures(
            coinType: coinType,
            txInputData: txInputData,
            signatures: unmarshalledSignature.asDataVector(),
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

    func buildInputForFeeCalculation(transaction: Transaction) throws -> VeChainFeeCalculator.Input {
        let input = try buildInput(transaction: transaction)

        return VeChainFeeCalculator.Input(
            gasPriceCoefficient: Int(input.gasPriceCoef),
            clauses: input.clauses.map(\.asFeeCalculationInput)
        )
    }

    private func buildInput(transaction: Transaction) throws -> VeChainSigningInput {
        guard let transactionParams = transaction.params as? VeChainTransactionParams else {
            throw WalletError.failedToBuildTx
        }

        let value = try transferValue(from: transaction)

        let clauses = [
            VeChainClause.with { input in
                input.value = value
                input.to = transaction.destinationAddress
            }
        ]

        let feeCalculator = VeChainFeeCalculator(blockchain: blockchain)
        let gas = feeCalculator.gas(for: clauses.map(\.asFeeCalculationInput))

        return VeChainSigningInput.with { input in
            input.chainTag = UInt32(chainTag)
            input.nonce = UInt64(transactionParams.nonce)
            input.blockRef = UInt64(transactionParams.lastBlockInfo.blockRef)
            input.expiration = UInt32(Constants.transactionExpiration)
            input.gasPriceCoef = 0
            input.gas = UInt64(gas)
            input.clauses = clauses
        }
    }

    private func transferValue(from transaction: Transaction) throws -> Data {
        let amount = transaction.amount
        let decimalValue = amount.value * pow(Decimal(10), amount.decimals)

        guard let bigUIntValue = BigUInt(decimal: decimalValue) else {
            throw WalletError.failedToBuildTx
        }

        return bigUIntValue.serialize()
    }

    /// VeChain is a fork of `Geth Classic`, so it expects the secp256k1's `recid` to have values in the 0...3 range.
    /// Therefore we have to convert value of the standard secp256k1's `recid` to match this expectation.
    private func unmarshalledSignature(from originalSignature: Data, publicKey: Data, hash: Data) throws -> Data {
        let signature = try Secp256k1Signature(with: originalSignature)
        let unmarshalledSignature = try signature.unmarshal(with: publicKey, hash: hash)

        guard unmarshalledSignature.v.count == Constants.recoveryIdLength else {
            throw WalletError.failedToBuildTx
        }

        let recoveryId = unmarshalledSignature.v[0] - Constants.recoveryIdDiff

        guard recoveryId >= Constants.recoveryIdLowerBound, recoveryId <= Constants.recoveryIdUpperBound else {
            throw WalletError.failedToBuildTx
        }

        return unmarshalledSignature.r + unmarshalledSignature.s + Data(recoveryId)
    }
}

// MARK: - Convenience extensions

private extension VeChainClause {
    var asFeeCalculationInput: VeChainFeeCalculator.Clause {
        return VeChainFeeCalculator.Clause(payload: data)
    }
}

// MARK: - Constants

private extension VeChainTransactionBuilder {
    enum Constants {
        /// `18` is the value used by the official `VeWorld` wallet app, multiplying it by 10 just in case.
        static let transactionExpiration = 18 * 10
        static let recoveryIdLength = 1
        static let recoveryIdDiff: UInt8 = 27
        static let recoveryIdLowerBound: UInt8 = 0
        static let recoveryIdUpperBound: UInt8 = 3
    }
}
