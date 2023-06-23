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
    
    // Transaction validity time. Currently we are using absolute values.
    // At 16 April 2023 was 90007700 slot number.
    // We need to rework this logic to use relative validity time.
    // TODO: https://tangem.atlassian.net/browse/IOS-3471
    // This can be constructed using absolute ttl slot from `/metadata` endpoint.
    private var timeToLife: UInt64 = 190000000
    
    private let coinType: CoinType = .cardano
    private var decimalValue: Decimal {
        Blockchain.cardano(shelley: true).decimalValue
    }

    init() {}
}

extension CardanoTransactionBuilder {
    func update(timeToLife: UInt64) {
        self.timeToLife = timeToLife
    }
    
    func update(outputs: [CardanoUnspentOutput]) {
        self.outputs = outputs
    }

    func buildForSign(transaction: Transaction) throws -> Data {
        let input = try buildCardanoSigningInput(transaction: transaction)
        let txInputData = try input.serializedData()

        let preImageHashes = TransactionCompiler.preImageHashes(coinType: .cardano, txInputData: txInputData)
        let preSigningOutput = try TxCompilerPreSigningOutput(serializedData: preImageHashes)
        
        print("preSigningOutput.data ->> ", preSigningOutput.data.hex)
//        print("walletPublicKey.hex ->> ", walletPublicKey.hex)

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
        publicKeys.add(data: signature.publicKey)

        let compileWithSignatures = TransactionCompiler.compileWithSignatures(
            coinType: coinType,
            txInputData: txInputData,
            signatures: signatures,
            publicKeys: publicKeys
        )

        let output: CardanoSigningOutput = try CardanoSigningOutput(serializedData: compileWithSignatures)

        if output.error != .ok {
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
        let amount = transaction.amount.value * decimalValue
        print("wallet core ->> amount", amount)

        var input = CardanoSigningInput.with {
            $0.transferMessage.toAddress = transaction.destinationAddress
            $0.transferMessage.changeAddress = transaction.changeAddress
            $0.transferMessage.amount = amount.roundedDecimalNumber.uint64Value
            $0.transferMessage.useMaxAmount = false
            $0.ttl = timeToLife
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

        let minChange = 1 * decimalValue
        if input.plan.change < minChange.roundedDecimalNumber.uint64Value {
            throw CardanoError.lowAda
        }

        return input
    }
}
