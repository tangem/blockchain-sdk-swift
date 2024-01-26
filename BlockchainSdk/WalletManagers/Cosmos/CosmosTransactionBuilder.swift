//
//  CosmosTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 11.04.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import WalletCore

class CosmosTransactionBuilder {
    private let publicKey: Data
    private let cosmosChain: CosmosChain
    private var sequenceNumber: UInt64?
    private var accountNumber: UInt64?
    
    init(publicKey: Data, cosmosChain: CosmosChain) throws {
        assert(
            PublicKey.isValid(data: publicKey, type: .secp256k1),
            "CosmosTransactionBuilder received invalid public key"
        )

        self.publicKey = publicKey
        self.cosmosChain = cosmosChain
    }
    
    func setSequenceNumber(_ sequenceNumber: UInt64) {
        self.sequenceNumber = sequenceNumber
    }
    
    func setAccountNumber(_ accountNumber: UInt64) {
        self.accountNumber = accountNumber
    }

    func buildForSign(transaction: Transaction) throws -> Data {
        let input = try makeInput(transaction: transaction, fee: transaction.fee)
        let txInputData = try input.serializedData()
        let preImageHashes = TransactionCompiler.preImageHashes(coinType: cosmosChain.coin, txInputData: txInputData)
        let output = try TxCompilerPreSigningOutput(serializedData: preImageHashes)

        if output.error != .ok {
            throw WalletError.failedToBuildTx
        }

        return output.dataHash
    }

    func buildForSend(transaction: Transaction, signature: Data) throws -> Data {
        let input = try makeInput(transaction: transaction, fee: transaction.fee)
        let txInputData = try input.serializedData()

        let publicKeys = DataVector()
        publicKeys.add(data: publicKey)

        let signatures = DataVector()
        // We should delete last byte from signature
        signatures.add(data: signature.dropLast(1))

        let transactionData = TransactionCompiler.compileWithSignatures(
            coinType: cosmosChain.coin,
            txInputData: txInputData,
            signatures: signatures,
            publicKeys: publicKeys
        )

        let output = try CosmosSigningOutput(serializedData: transactionData)

        if output.error != .ok {
            throw WalletError.failedToBuildTx
        }

        guard let outputData = output.serialized.data(using: .utf8) else {
            throw WalletError.failedToBuildTx
        }

        return outputData
    }

    private func makeInput(transaction: Transaction, fee: Fee?) throws -> CosmosSigningInput {
        let decimalValue: Decimal
        switch transaction.amount.type {
        case .coin:
            decimalValue = cosmosChain.blockchain.decimalValue
        case .token(let token):
            switch cosmosChain.blockchain.feePaidCurrency {
            case .coin:
                decimalValue = cosmosChain.blockchain.decimalValue
            case .sameCurrency:
                decimalValue = transaction.amount.type.token?.decimalValue ?? cosmosChain.blockchain.decimalValue
            case .token(let token):
                decimalValue = token.decimalValue
            }
        case .reserve:
            throw WalletError.failedToBuildTx
        }
        
        
        
        let message: CosmosMessage
        switch transaction.amount.type {
            // TODO: TerraUSD goes here
        case .coin:
            let amountInSmallestDenomination = ((transaction.amount.value * decimalValue) as NSDecimalNumber).uint64Value
            let denomination = try denomination(for: transaction.amount)

            let sendCoinsMessage = CosmosMessage.Send.with {
                $0.fromAddress = transaction.sourceAddress
                $0.toAddress = transaction.destinationAddress
                $0.amounts = [CosmosAmount.with {
                    $0.amount = "\(amountInSmallestDenomination)"
                    $0.denom = denomination
                }]
            }
            message = CosmosMessage.with {
                $0.sendCoinsMessage = sendCoinsMessage
            }
        case .token(let token):
            guard let amountBytes = transaction.amount.encoded else {
                throw WalletError.failedToBuildTx
            }

            let tokenMessage = CosmosMessage.WasmExecuteContractTransfer.with {
                $0.senderAddress = transaction.sourceAddress
                $0.recipientAddress = transaction.destinationAddress
                $0.contractAddress = token.contractAddress
                $0.amount = amountBytes
            }
            
            message = CosmosMessage.with {
                $0.wasmExecuteContractTransferMessage = tokenMessage
            }
        case .reserve:
            throw WalletError.failedToBuildTx
        }
        
        guard
            let accountNumber = self.accountNumber,
            let sequenceNumber = self.sequenceNumber
        else {
            throw WalletError.failedToBuildTx
        }
        
        let params = transaction.params as? CosmosTransactionParams
        let feeDenomination = try feeDenomination(for: transaction.amount)
        let input = CosmosSigningInput.with {
            $0.mode = .sync
            $0.signingMode = .protobuf;
            $0.accountNumber = accountNumber
            $0.chainID = cosmosChain.chainID
            $0.memo = params?.memo ?? ""
            $0.sequence = sequenceNumber
            $0.messages = [message]
            $0.publicKey = publicKey

            if let fee, let parameters = fee.parameters as? CosmosFeeParameters {
                let feeAmountInSmallestDenomination = (fee.amount.value * decimalValue).uint64Value

                $0.fee = CosmosFee.with {
                    $0.gas = parameters.gas
                    $0.amounts = [CosmosAmount.with {
                        $0.amount = "\(feeAmountInSmallestDenomination)"
                        $0.denom = feeDenomination
                    }]
                }
            }
        }
        
        return input
    }
    
    private func denomination(for amount: Amount) throws -> String {
        switch amount.type {
        case .coin:
            return cosmosChain.smallestDenomination
        case .token(let token):
            guard let tokenDenomination = cosmosChain.tokenDenomination(contractAddress: token.contractAddress, tokenCurrencySymbol: token.symbol)
            else {
                throw WalletError.failedToBuildTx
            }
            
            return tokenDenomination
        case .reserve:
            throw WalletError.failedToBuildTx
        }
    }
    
    
    private func feeDenomination(for amount: Amount) throws -> String {
        switch amount.type {
        case .coin:
            return cosmosChain.smallestDenomination
        case .token(let token):
            guard let tokenDenomination = cosmosChain.tokenFeeDenomination(contractAddress: token.contractAddress, tokenCurrencySymbol: token.symbol)
            else {
                throw WalletError.failedToBuildTx
            }
            
            return tokenDenomination
        case .reserve:
            throw WalletError.failedToBuildTx
        }
    }
}
