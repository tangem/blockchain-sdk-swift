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
    private let blockchain: Blockchain
    
    init(transactionBuilder: EthereumTransactionBuilder, blockchain: Blockchain) {
        self.transactionBuilder = transactionBuilder
        self.blockchain = blockchain
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
        let compiledTransactionData = blockchain.unsignedTransactionData(from: stakingTransaction.unsignedData)
        let compiledTransaction = try JSONDecoder().decode(
            EthereumCompiledTransaction.self,
            from: compiledTransactionData
        )
        
        guard let amountValue = stakingTransaction.amount.bigUIntValue else {
            throw EthereumTransactionBuilderError.invalidAmount
        }
        
        
        guard let gasLimit = BigUInt(compiledTransaction.gasLimit.removeHexPrefix(), radix: 16) else {
            throw EthereumTransactionBuilderError.feeParametersNotFound
        }
        let parameters: EthereumFeeParameters
        
        if let baseFee = compiledTransaction.maxFeePerGas.flatMap { BigUInt($0, radix: 16) },
           let priorityFee = compiledTransaction.maxPriorityFeePerGas.flatMap({ BigUInt($0, radix: 16) }) {
            parameters = EthereumEIP1559FeeParameters(gasLimit: gasLimit, baseFee: baseFee, priorityFee: priorityFee)
           } else if let gasPrice = compiledTransaction.gasPrice.flatMap { BigUInt($0.removeHexPrefix(), radix: 16) } {
            parameters = EthereumLegacyFeeParameters(gasLimit: gasLimit, gasPrice: gasPrice)
        } else {
            throw EthereumTransactionBuilderError.feeParametersNotFound
        }
        
        return try transactionBuilder.buildSigningInput(
            // TODO: refactor, 'user' field is used only in erc20Transfer, consider moving elsewhere?
            destination: .contract(user: "", contract: compiledTransaction.to, value: amountValue),
            fee: Fee(
                stakingTransaction.fee.amount,
                parameters: parameters
            ),
            parameters: EthereumTransactionParams(
                data: Data(hex: compiledTransaction.data),
                nonce: compiledTransaction.nonce
            )
        )
    }
}

fileprivate struct EthereumCompiledTransaction: Decodable {
    let from: String
    let gasLimit: String
    let gasPrice: String?
    let to: String
    let data: String
    let nonce: Int
    let type: Int
    let maxFeePerGas: String?
    let maxPriorityFeePerGas: String?
    let chainId: Int
}

private extension Blockchain {
    func unsignedTransactionData(from transactionString: String) -> Data {
        switch self {
        case .bsc: transactionString.data(using: .utf8) ?? Data()
        default: Data(hex: transactionString)
        }
    }
}
