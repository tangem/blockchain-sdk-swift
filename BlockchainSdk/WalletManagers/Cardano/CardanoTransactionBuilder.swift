//
//  CardanoTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 20.06.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import WalletCore
import BigInt

// You can decode your CBOR transaction here: https://cbor.me
class CardanoTransactionBuilder {
    private var outputs: [CardanoUnspentOutput] = []
    private let coinType: CoinType = .cardano

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
        
        print("preSigningOutput.dataHash ->>", preSigningOutput.dataHash)

        return preSigningOutput.dataHash
    }

    func buildForSend(transaction: Transaction, signature: SignatureInfo) throws -> Data {
        let input = try buildCardanoSigningInput(transaction: transaction)
        let txInputData = try input.serializedData()

        let signatures = DataVector()
        signatures.add(data: signature.signature)
        
        let publicKeys = DataVector()
        
        print("signature ->>", signature.description)
        
        // WalletCore used here `.ed25519Cardano` curve with 128 bytes publicKey.
        // Calculated as: chainCode + secondPubKey + chainCode
        // The number of bytes in a Cardano public key (two ed25519 public key + chain code).
        // We should add dummy chain code in publicKey
        let publicKey = signature.publicKey + Data(count: 32 * 3)
        publicKeys.add(data: publicKey)

        let compileWithSignatures = TransactionCompiler.compileWithSignatures(
            coinType: coinType,
            txInputData: txInputData,
            signatures: signatures,
            publicKeys: publicKeys
        )

        let output = try CardanoSigningOutput(serializedData: compileWithSignatures)

        if output.error != .ok {
            print("CardanoSigningOutput has a error: \(output.errorMessage)")
            throw WalletError.failedToBuildTx
        }
        
        if output.encoded.isEmpty {
            throw WalletError.failedToBuildTx
        }

        print("output.encoded ->>", output.encoded.hex)
        
        return output.encoded
    }

    func estimatedFee(transaction: Transaction) throws -> Decimal {
        let input = try buildCardanoSigningInput(transaction: transaction)
        return Decimal(input.plan.fee)
    }

    func buildCardanoSigningInput(transaction: Transaction) throws -> CardanoSigningInput {
        let decimalValue = pow(10, transaction.amount.decimals)
        let uint64Amount = (transaction.amount.value * decimalValue).roundedDecimalNumber.uint64Value

        var input = CardanoSigningInput.with {
            $0.transferMessage.toAddress = transaction.destinationAddress
            $0.transferMessage.changeAddress = transaction.changeAddress
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
        print("outputs ->>", outputs)
        input.utxos = outputs.map { output -> CardanoTxInput in
            CardanoTxInput.with {
                $0.outPoint.txHash = Data(hexString: output.transactionHash)
                $0.outPoint.outputIndex = UInt64(output.outputIndex)
                $0.address = output.address
                $0.amount = output.amount.roundedDecimalNumber.uint64Value
                
                if !output.assets.isEmpty {
                    $0.tokenAmount = output.assets.map { asset in
                        CardanoTokenAmount.with {
                            $0.policyID = asset.policyID // "9a9693a9a37912a5097918f97918d15240c92ab729a0b7c4aa144d77"
                            $0.assetName = asset.assetName // "CUBY"
                            $0.amount = BigInt(asset.amount).serialize() //  Data(hexString: "2dc6c0")! // 3000000
                        }
                    }
                }
            }
        }
        
        input.plan = AnySigner.plan(input: input, coin: coinType)
        
        switch transaction.amount.type {
        case .token(let token):
            var toTokenBundle = CardanoTokenBundle()
            let toToken = CardanoTokenAmount.with {
                $0.policyID = token.contractAddress
                $0.assetName = token.symbol
                // Should set amount as hex e.g. "01312d00" = 20000000
                $0.amount = BigUInt(uint64Amount).serialize()
            }
            
            toTokenBundle.token.append(toToken)
            
            // check min ADA amount, set it
            let inputTokenAmountSerialized = try toTokenBundle.serializedData()
            let minAmount = CardanoMinAdaAmount(tokenBundle: inputTokenAmountSerialized)
            
            // We should set minAmount because main amount in utxo must not be empty
            input.transferMessage.amount = minAmount
            input.transferMessage.tokenAmount = toTokenBundle
        case .coin:
            let minChange = (1 * decimalValue).uint64Value
            let acceptableChangeRange: ClosedRange<UInt64> = 1 ... minChange
            
            if acceptableChangeRange.contains(input.plan.change) {
                throw CardanoError.lowAda
            }
            
            // For coin just set amount which will be sent
              input.transferMessage.amount = uint64Amount
        case .reserve:
            throw WalletError.empty
        }

        return input
    }
}
