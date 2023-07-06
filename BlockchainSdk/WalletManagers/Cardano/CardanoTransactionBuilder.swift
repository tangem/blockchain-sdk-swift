//
//  CardanoTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 20.06.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import WalletCore

// You can decode your CBOR transaction here: https://cbor.me
class CardanoTransactionBuilder {
    private var outputs: [CardanoUnspentOutput] = []
    private let coinType: CoinType = .cardano
    private var decimalValue: Decimal {
        // It isn't important shelley or byron, decimalValue is equal for both cases.
        Blockchain.cardano(shelley: true).decimalValue
    }

    init() {}
}

extension CardanoTransactionBuilder {
    func update(outputs: [CardanoUnspentOutput]) {
        self.outputs = outputs
    }

    func buildForSign(transaction: Transaction) throws -> Data {
        let input = try buildCardanoSigningInput(transaction: transaction)
        let txInputData = try input.serializedData()

        let preImageHashes = TransactionCompiler.preImageHashes(coinType: coinType, txInputData: txInputData)
        let preSigningOutput = try TxCompilerPreSigningOutput(serializedData: preImageHashes)

        if preSigningOutput.error != .ok {
            throw WalletError.failedToBuildTx
        }

        return preSigningOutput.dataHash
    }

    func buildForSend(transaction: Transaction, signature: SignatureInfo) throws -> Data {
        let input = try buildCardanoSigningInput(transaction: transaction)
        let txInputData = try input.serializedData()

        let signatures = DataVector()
        signatures.add(data: signature.signature)
        
        let publicKeys = DataVector()
        publicKeys.add(data: signature.publicKey.aligned(to: 128)) // extend public key

        let compileWithSignatures = TransactionCompiler.compileWithSignatures(
            coinType: coinType,
            txInputData: txInputData,
            signatures: signatures,
            publicKeys: publicKeys
        )

        let output = try CardanoSigningOutput(serializedData: compileWithSignatures)

        if output.error != .ok {
            throw WalletError.failedToBuildTx
        }
        
        if output.encoded.isEmpty {
            throw WalletError.failedToBuildTx
        }

        return output.encoded
    }

    func estimatedFee(transaction: Transaction) throws -> Decimal {
        var input = try buildCardanoSigningInput(transaction: transaction)
        input.plan = AnySigner.plan(input: input, coin: coinType)

        return Decimal(input.plan.fee)
    }

    func buildCardanoSigningInput(transaction: Transaction) throws -> CardanoSigningInput {
        let amount = transaction.amount.value * decimalValue
        var input = CardanoSigningInput.with {
            $0.transferMessage.toAddress = transaction.destinationAddress
            $0.transferMessage.changeAddress = transaction.changeAddress
            $0.transferMessage.amount = amount.roundedDecimalNumber.uint64Value
            $0.transferMessage.useMaxAmount = false
            // Transaction validity time. Currently we are using absolute values.
            // At 16 April 2023 was 90007700 slot number.
            // We need to rework this logic to use relative validity time.
            // TODO: https://tangem.atlassian.net/browse/IOS-3471
            // This can be constructed using absolute ttl slot from `/metadata` endpoint.
            $0.ttl = 190000000
        }

        if outputs.isEmpty {
            throw CardanoError.noUnspents
        }

        input.utxos = outputs.map { output -> CardanoTxInput in
            CardanoTxInput.with {
                $0.outPoint.txHash = Data(hexString: output.transactionHash)
                $0.outPoint.outputIndex = UInt64(output.outputIndex)
                $0.address = output.address
                $0.amount = output.amount.roundedDecimalNumber.uint64Value
            }
        }

        let minChange = (1 * decimalValue).uint64Value
        let acceptableChangeRange: ClosedRange<UInt64> = 1 ... minChange

        if acceptableChangeRange.contains(input.plan.change) {
            throw CardanoError.lowAda
        }

        return input
    }
}
