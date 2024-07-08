//
//  TransactionCreator.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 12.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import BigInt
import Foundation

public protocol TransactionCreator: TransactionValidator {
    func createTransaction(
        amount: Amount,
        fee: Fee,
        sourceAddress: String?,
        destinationAddress: String,
        changeAddress: String?,
        contractAddress: String?
    ) throws -> Transaction
    
    func createTransaction(
        amount: Amount,
        fee: Fee,
        sourceAddress: String?,
        destinationAddress: String,
        changeAddress: String?,
        contractAddress: String?
    ) async throws -> Transaction
}

// MARK: - Default

public extension TransactionCreator {
    func createTransaction(
        amount: Amount,
        fee: Fee,
        sourceAddress: String? = nil,
        destinationAddress: String,
        changeAddress: String? = nil,
        contractAddress: String? = nil
    ) throws -> Transaction {
        try validate(amount: amount, fee: fee)
        
        return Transaction(
            amount: amount,
            fee: fee,
            sourceAddress: sourceAddress ?? defaultSourceAddress,
            destinationAddress: destinationAddress,
            changeAddress: changeAddress ?? defaultChangeAddress,
            contractAddress: contractAddress ?? amount.type.token?.contractAddress
        )
    }
    
    func createTransaction(
        amount: Amount,
        fee: Fee,
        sourceAddress: String? = nil,
        destinationAddress: String,
        changeAddress: String? = nil,
        contractAddress: String? = nil
    ) async throws -> Transaction {
        let transaction = Transaction(
            amount: amount,
            fee: fee,
            sourceAddress: defaultSourceAddress,
            destinationAddress: destinationAddress,
            changeAddress: changeAddress ?? defaultChangeAddress,
            contractAddress: contractAddress ?? amount.type.token?.contractAddress
        )
        
        try await validate(transaction: transaction)
        
        return transaction
    }
    
    func createTransaction(
        amount: Amount,
        fee: Fee,
        blockchain: Blockchain,
        sourceAddress: String? = nil,
        destinationAddress: String,
        changeAddress: String? = nil,
        contractAddress: String? = nil
    ) throws -> Transaction {
        // This is a workaround for sending a Mantle transaction.
        // Unfortunately, Mantle's current implementation does not conform to our existing fee calculation rules.
        // https://tangem.slack.com/archives/GMXC6PP71/p1719591856597299?thread_ts=1714215815.690169&cid=GMXC6PP71
        var fee = fee
        if case .mantle = blockchain {
            let parameters = (fee.parameters as? EthereumEIP1559FeeParameters).map { parameters in
                EthereumEIP1559FeeParameters(
                    gasLimit: BigUInt(ceil(Double(parameters.gasLimit) * 0.7)),
                    maxFeePerGas: parameters.maxFeePerGas,
                    priorityFee: parameters.priorityFee
                )
            }
            fee = Fee(fee.amount, parameters: parameters)
        }
        
        return try createTransaction(
            amount: amount,
            fee: fee,
            sourceAddress: sourceAddress,
            destinationAddress: destinationAddress,
            changeAddress: changeAddress,
            contractAddress: contractAddress
        )
    }
}
