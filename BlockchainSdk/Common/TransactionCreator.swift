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
        sourceAddress: String?,
        destinationAddress: String,
        changeAddress: String?,
        contractAddress: String?,
        date: Date,
        status: TransactionStatus
    ) throws -> Transaction
    
    func validate(fee: Amount) throws
    func validate(amount: Amount) throws
}

@available(iOS 13.0, *)
public extension TransactionCreator {
    func createTransaction(
        amount: Amount,
        fee: Amount,
        sourceAddress: String? = nil,
        destinationAddress: String,
        changeAddress: String? = nil,
        contractAddress: String? = nil,
        date: Date = Date(),
        status: TransactionStatus = .unconfirmed
    ) throws -> Transaction {
        try self.createTransaction(
            amount: amount,
            fee: fee,
            sourceAddress: sourceAddress,
            destinationAddress: destinationAddress,
            changeAddress: changeAddress,
            contractAddress: contractAddress,
            date: date,
            status: status
        )
    }
}

