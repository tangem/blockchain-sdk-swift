//
//  TransactionCreator.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 12.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public protocol TransactionCreator {
    func createTransaction(
        amount: Amount,
        fee: Fee,
        sourceAddress: String?,
        destinationAddress: String,
        changeAddress: String?,
        contractAddress: String?
    ) -> Transaction
}

public extension TransactionCreator {
    func createTransaction(
        amount: Amount,
        fee: Fee,
        sourceAddress: String? = nil,
        destinationAddress: String,
        changeAddress: String? = nil,
        contractAddress: String? = nil
    ) -> Transaction {
        createTransaction(
            amount: amount,
            fee: fee,
            sourceAddress: sourceAddress,
            destinationAddress: destinationAddress,
            changeAddress: changeAddress,
            contractAddress: contractAddress
        )
    }
}

// MARK: - WalletProvider

public extension TransactionCreator where Self: WalletProvider {
    func createTransaction(
        amount: Amount,
        fee: Fee,
        sourceAddress: String? = nil,
        destinationAddress: String,
        changeAddress: String? = nil,
        contractAddress: String? = nil
    ) -> Transaction {
        Transaction(
            amount: amount,
            fee: fee,
            sourceAddress: sourceAddress ?? defaultSourceAddress,
            destinationAddress: destinationAddress,
            changeAddress: changeAddress ?? defaultChangeAddress,
            contractAddress: contractAddress ?? amount.type.token?.contractAddress
        )
    }
}

// MARK: - TransactionValidator

public extension TransactionCreator where Self: TransactionValidator {
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
        try await validate(amount: amount, fee: fee, destination: .address(destinationAddress))
        
        return Transaction(
            amount: amount,
            fee: fee,
            sourceAddress: sourceAddress ?? defaultSourceAddress,
            destinationAddress: destinationAddress,
            changeAddress: changeAddress ?? defaultChangeAddress,
            contractAddress: contractAddress ?? amount.type.token?.contractAddress
        )
    }
}
