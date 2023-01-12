//
//  TransactionCreator.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 12.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
public protocol TransactionCreator {
    func createTransaction(
        amount: Amount,
        fee: Amount,
        destinationAddress: String,
        sourceAddress: String?,
        changeAddress: String?,
        contractAddress: String?
    ) throws -> Transaction
    
    func validate(fee: Amount) -> TransactionError?
    func validate(amount: Amount) -> TransactionError?
}

@available(iOS 13.0, *)
public extension TransactionCreator {
    func createTransaction(
        amount: Amount,
        fee: Amount,
        destinationAddress: String,
        sourceAddress: String? = nil,
        changeAddress: String? = nil,
        contractAddress: String? = nil
    ) throws -> Transaction {
        try self.createTransaction(
            amount: amount,
            fee: fee,
            destinationAddress: destinationAddress,
            sourceAddress: sourceAddress,
            changeAddress: changeAddress,
            contractAddress: contractAddress
        )
    }
}

