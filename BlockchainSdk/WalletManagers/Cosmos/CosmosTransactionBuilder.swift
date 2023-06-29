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
    private let wallet: Wallet
    private let cosmosChain: CosmosChain
    private var sequenceNumber: UInt64?
    private var accountNumber: UInt64?
    
    init(wallet: Wallet, cosmosChain: CosmosChain) {
        self.wallet = wallet
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
        publicKeys.add(data: wallet.publicKey.blockchainKey)

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
        let params = transaction.params as? CosmosTransactionParams
        let decimalValue = transaction.amount.type.token?.decimalValue ?? cosmosChain.blockchain.decimalValue
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
        
        let message = CosmosMessage.with {
            $0.sendCoinsMessage = sendCoinsMessage
        }
        
        guard
            let accountNumber = self.accountNumber,
            let sequenceNumber = self.sequenceNumber
        else {
            throw WalletError.failedToBuildTx
        }
        
        let input = CosmosSigningInput.with {
            $0.mode = .sync
            $0.signingMode = .protobuf;
            $0.accountNumber = accountNumber
            $0.chainID = cosmosChain.chainID
            $0.memo = params?.memo ?? ""
            $0.sequence = sequenceNumber
            $0.messages = [message]
            $0.publicKey = wallet.publicKey.blockchainKey

            if let fee, let parameters = fee.parameters as? CosmosFeeParameters {
                let feeAmountInSmallestDenomination = (fee.amount.value * decimalValue).uint64Value

                $0.fee = CosmosFee.with {
                    $0.gas = parameters.gas
                    $0.amounts = [CosmosAmount.with {
                        $0.amount = "\(feeAmountInSmallestDenomination)"
                        $0.denom = denomination
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
            guard let tokenDenomination = cosmosChain.tokenDenominationByContractAddress[token.contractAddress] else {
                throw WalletError.failedToBuildTx
            }
            
            return tokenDenomination
        case .reserve:
            throw WalletError.failedToBuildTx
        }
    }
}
