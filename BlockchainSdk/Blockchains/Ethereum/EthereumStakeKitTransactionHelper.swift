//
//  EthereumStakeKitTransactionHelper.swift
//  BlockchainSdk
//
//  Created by Dmitry Fedorov on 16.08.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import WalletCore
import BigInt

struct EthereumStakeKitTransactionHelper {
    private let transactionBuilder: EthereumTransactionBuilder
    
    init(transactionBuilder: EthereumTransactionBuilder) {
        self.transactionBuilder = transactionBuilder
    }
    
    func prepareForSign(
        _ stakingTransaction: StakeKitTransaction
    ) throws -> Data {
        let input = try buildSigningInput(
            stakingTransaction: stakingTransaction
        )
        let preSigningOutput = try transactionBuilder.buildTxCompilerPreSigningOutput(input: input)
        return preSigningOutput.dataHash
    }
    
    func prepareForSend(
        stakingTransaction: StakeKitTransaction,
        signatureInfo: SignatureInfo
    ) throws -> Data {
        let input = try buildSigningInput(
            stakingTransaction: stakingTransaction
        )
        let output = try transactionBuilder.buildSigningOutput(input: input, signatureInfo: signatureInfo)
        return output.encoded
    }
    
    private func buildSigningInput(
        stakingTransaction: StakeKitTransaction
    ) throws -> EthereumSigningInput {
        let compiledTransactionData = Data(hex: stakingTransaction.unsignedData)
        let compiledTransaction = try JSONDecoder().decode(
            EthereumCompiledTransaction.self,
            from: compiledTransactionData
        )
        
        guard let amountValue = stakingTransaction.amount.bigUIntValue else {
            throw EthereumTransactionBuilderError.invalidAmount
        }
        
        guard let gasLimit = BigUInt(compiledTransaction.gasLimit, radix: 16),
              let baseFee = BigUInt(compiledTransaction.maxFeePerGas, radix: 16),
              let priorityFee = BigUInt(compiledTransaction.maxPriorityFeePerGas, radix: 16) else {
            throw EthereumTransactionBuilderError.feeParametersNotFound
        }
                
        return try transactionBuilder.buildSigningInput(
            // TODO: refactor, 'user' field is used only in erc20Transfer, consider moving elsewhere?
            destination: .contract(user: "", contract: compiledTransaction.to, value: amountValue),
            fee: Fee(
                stakingTransaction.fee.amount,
                parameters: EthereumEIP1559FeeParameters(gasLimit: gasLimit, baseFee: baseFee, priorityFee: priorityFee)
            ),
            parameters: EthereumTransactionParams(
                data: Data(hex: compiledTransaction.data),
                nonce: compiledTransaction.nonce
            )
        )
    }
}
