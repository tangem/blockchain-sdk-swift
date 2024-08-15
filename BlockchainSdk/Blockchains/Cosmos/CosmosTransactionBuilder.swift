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
    
    // MARK: Regular transaction

    func buildForSign(transaction: Transaction) throws -> Data {
        let input = try makeInput(transaction: transaction, fee: transaction.fee)
        let txInputData = try input.serializedData()
        
        return try buildForSignInternal(txInputData: txInputData)
    }

    func buildForSend(transaction: Transaction, signature: Data) throws -> Data {
        let input = try makeInput(transaction: transaction, fee: transaction.fee)
        let txInputData = try input.serializedData()
        
        return try buildForSendInternal(txInputData: txInputData, signature: signature)
    }
    
    // MARK: Staking
    
    func buildForSign(stakingTransaction: StakeKitTransaction) throws -> Data {
        let input = try makeInput(stakingTransaction: stakingTransaction)
        let txInputData = try input.serializedData()
        
        return try buildForSignInternal(txInputData: txInputData)
    }
    
    func buildForSend(
        stakingTransaction: StakeKitTransaction,
        signature: Data
    ) throws -> Data {
        let input = try makeInput(stakingTransaction: stakingTransaction)
        let txInputData = try input.serializedData()
        
        return try buildForSendInternal(txInputData: txInputData, signature: signature)
    }

    // MARK: Private

    private func buildForSignInternal(txInputData: Data) throws -> Data {
        let preImageHashes = TransactionCompiler.preImageHashes(coinType: cosmosChain.coin, txInputData: txInputData)
        let output = try TxCompilerPreSigningOutput(serializedData: preImageHashes)

        if output.error != .ok {
            throw WalletError.failedToBuildTx
        }

        return output.dataHash
    }

    private func buildForSendInternal(txInputData: Data, signature: Data) throws -> Data {
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
        case .token:
            switch cosmosChain.blockchain.feePaidCurrency {
            case .coin:
                decimalValue = cosmosChain.blockchain.decimalValue
            case .sameCurrency:
                decimalValue = transaction.amount.type.token?.decimalValue ?? cosmosChain.blockchain.decimalValue
            case .token(let token):
                decimalValue = token.decimalValue
            case .feeResource:
                throw WalletError.empty
            }
        case .reserve, .feeResource:
            throw WalletError.failedToBuildTx
        }
        
        let message: CosmosMessage
        if let token = transaction.amount.type.token, cosmosChain.allowCW20Tokens {
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
        } else {
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
    
    private func makeInput(
        stakingTransaction: StakeKitTransaction
    ) throws -> CosmosSigningInput {
        guard let accountNumber, let sequenceNumber else {
            throw WalletError.failedToBuildTx
        }
        
        let stakingProtoMessage = try CosmosProtoMessage(serializedData: Data(hex: stakingTransaction.unsignedData))
        
        let feeMessage = stakingProtoMessage.feeAndKeyContainer.feeContainer
        let feeValue = feeMessage.feeAmount
        
        guard let message = CosmosMessage.createStakeMessage(message: stakingProtoMessage.delegateContainer.delegate) else {
            throw WalletError.failedToBuildTx
        }
        let fee = CosmosFee.with { fee in
            fee.gas = feeMessage.gas
            fee.amounts = [
                CosmosAmount.with { amount in
                    amount.amount = feeValue.amount
                    amount.denom = feeValue.denomination
                }
            ]
        }
        
        let input = CosmosSigningInput.with {
            $0.mode = .sync
            $0.signingMode = .protobuf
            $0.accountNumber = accountNumber
            $0.chainID = cosmosChain.chainID
            $0.sequence = sequenceNumber
            $0.publicKey = publicKey
            $0.messages = [message]
            $0.privateKey = Data(repeating: 1, count: 32)
            $0.fee = fee
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
        case .reserve, .feeResource:
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
        case .reserve, .feeResource:
            throw WalletError.failedToBuildTx
        }
    }
}

extension CosmosMessage {
    static func createStakeMessage(
        message: CosmosProtoMessage.CosmosMessageDelegate
    ) -> Self? {
        let type = message.messageType
        guard message.hasDelegateData else {
            return nil
        }
        let delegateData = message.delegateData
        
        switch type {
        case (let string) where string.contains(Constants.delegateMessage.rawValue):
            let delegateAmount = delegateData.delegateAmount
            let stakeMessage = CosmosMessage.Delegate.with { delegate in
                delegate.amount = CosmosAmount.with { amount in
                    amount.amount = delegateAmount.amount
                    amount.denom = delegateAmount.denomination
                }
                delegate.delegatorAddress = delegateData.delegatorAddress
                delegate.validatorAddress = delegateData.validatorAddress
            }
            return CosmosMessage.with {
                $0.stakeMessage = stakeMessage
            }
        case (let string) where string.contains(Constants.withdrawMessage.rawValue):
            let withdrawMessage = CosmosMessage.WithdrawDelegationReward.with { reward in
                reward.delegatorAddress = delegateData.delegatorAddress
                reward.validatorAddress = delegateData.validatorAddress
            }
            return CosmosMessage.with {
                $0.withdrawStakeRewardMessage = withdrawMessage
            }
        case (let string) where string.contains(Constants.undelegateMessage.rawValue):
            let delegateAmount = delegateData.delegateAmount
            let unstakeMessage = CosmosMessage.Undelegate.with { delegate in
                delegate.amount = CosmosAmount.with { amount in
                    amount.amount = delegateAmount.amount
                    amount.denom = delegateAmount.denomination
                }
                delegate.delegatorAddress = delegateData.delegatorAddress
                delegate.validatorAddress = delegateData.validatorAddress
            }
            return CosmosMessage.with {
                $0.unstakeMessage = unstakeMessage
            }
        default: return nil
        }
    }
}

extension CosmosMessage {
    enum Constants: String {
        case delegateMessage = "MsgDelegate"
        case withdrawMessage = "MsgWithdrawDelegatorReward"
        case undelegateMessage = "MsgUndelegate"
    }
}
