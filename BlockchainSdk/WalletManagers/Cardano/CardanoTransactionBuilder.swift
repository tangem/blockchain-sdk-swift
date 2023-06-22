//
//  CardanoTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 20.06.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import WalletCore

class CardanoTransactionBuilder {
    private var outputs: [CardanoUnspentOutput] = []

    private let coinType: CoinType = .cardano
    private let blockchain = Blockchain.cardano(shelley: true)

    init() {}
}

extension CardanoTransactionBuilder {
    func updateOutputs(outputs: [CardanoUnspentOutput]) {
        self.outputs = outputs
    }

    func buildForSign(transaction: Transaction) throws -> Data {
        let input = try buildCardanoSigningInput(transaction: transaction)
        let txInputData = try input.serializedData()

        let preImageHashes = TransactionCompiler.preImageHashes(coinType: .cardano, txInputData: txInputData)
        let preSigningOutput = try TxCompilerPreSigningOutput(serializedData: preImageHashes)

        if preSigningOutput.error != .ok {
            assertionFailure("\(preSigningOutput.errorMessage)")
            throw WalletError.failedToBuildTx
        }

        return preSigningOutput.data
    }

    func buildForSend(transaction: Transaction, publicKey: Data, signatures: [Data]) throws -> Data {
        let input = try buildCardanoSigningInput(transaction: transaction)
        let txInputData = try input.serializedData()

        let signatures = DataVector()
        let publicKeys = DataVector()

        let compileWithSignatures = TransactionCompiler.compileWithSignatures(coinType: coinType, txInputData: txInputData, signatures: signatures, publicKeys: publicKeys)
        let output: CardanoSigningOutput = try CardanoSigningOutput(serializedData: compileWithSignatures)

        if output.error != .ok {
            assertionFailure("\(output.errorMessage)")
            throw WalletError.failedToBuildTx
        }

        print("wallet core ->> output.encoded", output.encoded.hex)

        return output.encoded
    }

    func estimatedFee(transaction: Transaction) throws -> Decimal {
        var input = try buildCardanoSigningInput(transaction: transaction)
        print("wallet core ->> fee", input.plan.fee)

        return Decimal(input.plan.fee)
    }

    func buildCardanoSigningInput(transaction: Transaction) throws -> CardanoSigningInput {
        var amount = transaction.amount.value
        amount *= blockchain.decimalValue

        print("wallet core ->> amount", amount)

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

        input.plan = AnySigner.plan(input: input, coin: coinType)

        let minChange = 1 * blockchain.decimalValue
        if input.plan.change < minChange.roundedDecimalNumber.uint64Value {
            throw CardanoError.lowAda
        }

        return input
    }
}
