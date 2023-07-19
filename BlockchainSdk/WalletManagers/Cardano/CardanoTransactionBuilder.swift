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
import TangemSdk

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
            Log.debug("CardanoPreSigningOutput has a error: \(preSigningOutput.errorMessage)")
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
            Log.debug("CardanoSigningOutput has a error: \(output.errorMessage)")
            throw WalletError.failedToBuildTx
        }
        
        if output.encoded.isEmpty {
            throw WalletError.failedToBuildTx
        }
        
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

        input.utxos = outputs.map { output -> CardanoTxInput in
            CardanoTxInput.with {
                $0.outPoint.txHash = Data(hexString: output.transactionHash)
                $0.outPoint.outputIndex = UInt64(output.outputIndex)
                $0.address = output.address
                $0.amount = output.amount.roundedDecimalNumber.uint64Value
                
                if !output.assets.isEmpty {
                    $0.tokenAmount = output.assets.map { asset in
                        CardanoTokenAmount.with {
                            $0.policyID = asset.policyID
                            $0.assetNameHex = asset.assetNameHex
                            // Amount in hexadecimal e.g. 2dc6c0 = 3000000
                            $0.amount = BigInt(asset.amount).serialize()
                        }
                    }
                }
            }
        }
                
        switch transaction.amount.type {
        case .token(let token):
            // We should use this HACK here to find
            // right policyID and the exadecimal asset name
            // Must be used exactly same as in utxo
            let asset = outputs.first(where: { output in
                output.assets.contains(where: { asset in
                    token.contractAddress.hasPrefix(asset.policyID)
                })
            })?.assets.first

            guard let asset else {
                throw WalletError.failedToBuildTx
            }
            
            var toTokenBundle = CardanoTokenBundle()
            let toToken = CardanoTokenAmount.with {
                $0.policyID = asset.policyID
                $0.assetNameHex = asset.assetNameHex
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
            // Min change is 1 ADA. It's also a dust value.
            let minChange = (1 * decimalValue).uint64Value
            let change = input.plan.change
            
            if change > 0, change < minChange {
                throw CardanoError.lowAda
            }
            
            // For coin just set amount which will be sent
              input.transferMessage.amount = uint64Amount
        case .reserve:
            throw WalletError.empty
        }
        
        input.plan = AnySigner.plan(input: input, coin: coinType)
        
        if input.plan.error != .ok {
            Log.debug("CardanoSigningInput has a error: \(input.plan.error)")
            throw WalletError.failedToBuildTx
        }
        
        return input
    }
}
