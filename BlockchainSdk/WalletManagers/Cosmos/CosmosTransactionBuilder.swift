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

    func buildForSign(amount: Amount, source: String, destination: String, feeAmount: Decimal?, gas: UInt64?, params: CosmosTransactionParams?) throws -> Data {
        let input = try makeInput(amount: amount, source: source, destination: destination, feeAmount: feeAmount, gas: gas, params: params)
        let txInputData = try input.serializedData()
        let preImageHashes = TransactionCompiler.preImageHashes(coinType: cosmosChain.coin, txInputData: txInputData)
        let output = try TxCompilerPreSigningOutput(serializedData: preImageHashes)

        if output.error != .ok {
            assertionFailure("\(output.errorMessage)")
            throw WalletError.failedToBuildTx
        }

        return output.dataHash
    }
    
    func buildForSend(amount: Amount, source: String, destination: String, feeAmount: Decimal?, gas: UInt64?, params: CosmosTransactionParams?, signature: Data) throws -> Data {
        let input = try makeInput(amount: amount, source: source, destination: destination, feeAmount: feeAmount, gas: gas, params: params)
        let txInputData = try input.serializedData()

        let publicKeys = DataVector()
        publicKeys.add(data: wallet.publicKey.blockchainKey)

        let signatures = DataVector()
        signatures.add(data: signature)

        let compileWithSignatures = TransactionCompiler.compileWithSignatures(
            coinType: cosmosChain.coin,
            txInputData: txInputData,
            signatures: signatures,
            publicKeys: publicKeys
        )

        let output = try CosmosSigningOutput(serializedData: compileWithSignatures)

        if output.error != .ok {
            assertionFailure("\(output.errorMessage)")
            throw WalletError.failedToBuildTx
        }

        guard let outputData = output.serialized.data(using: .utf8) else {
            throw WalletError.failedToBuildTx
        }

        return outputData
    }

    private func makeInput(amount: Amount, source: String, destination: String, feeAmount: Decimal?, gas: UInt64?, params: CosmosTransactionParams?) throws -> CosmosSigningInput {
        let decimalValue = amount.type.token?.decimalValue ?? cosmosChain.blockchain.decimalValue
        let amountInSmallestDenomination = ((amount.value * decimalValue) as NSDecimalNumber).uint64Value
        
        let denomination = try denomination(for: amount)
        let sendCoinsMessage = CosmosMessage.Send.with {
            $0.fromAddress = source
            $0.toAddress = destination
            $0.amounts = [CosmosAmount.with {
                $0.amount = "\(amountInSmallestDenomination)"
                $0.denom = denomination
            }]
        }
        
        let message = CosmosMessage.with {
            $0.sendCoinsMessage = sendCoinsMessage
        }
        
        let fee: CosmosFee?
        if let feeAmount, let gas {
            let feeAmountInSmallestDenomination = (feeAmount * decimalValue as NSDecimalNumber).uint64Value
            
            fee = CosmosFee.with {
                $0.gas = gas
                $0.amounts = [CosmosAmount.with {
                    $0.amount = "\(feeAmountInSmallestDenomination)"
                    $0.denom = denomination
                }]
            }
        } else {
            fee = nil
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
            if let fee = fee {
                $0.fee = fee
            }
            $0.publicKey = wallet.publicKey.blockchainKey
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
