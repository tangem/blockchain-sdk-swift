//
//  TransactionRecord.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 25.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public struct TransactionRecord: Hashable {
    let hash: String
    let sourceAddress: String
    let destinationAddress: String
    let amount: Decimal
    let fee: Decimal
    let status: TransactionStatus
    let type: TransactionType
    let date: Date?
    let contractAddress: String?
    
    public init(
        hash: String,
        sourceAddress: String,
        destinationAddress: String,
        amount: Decimal,
        fee: Decimal,
        status: TransactionStatus,
        type: TransactionType,
        date: Date? = nil,
        contractAddress: String? = nil
    ) {
        self.hash = hash
        self.sourceAddress = sourceAddress
        self.destinationAddress = destinationAddress
        self.amount = amount
        self.fee = fee
        self.status = status
        self.type = type
        self.date = date
        self.contractAddress = contractAddress
    }
}

public extension TransactionRecord {
    enum TransactionType: String, Hashable {
        case send
        case receive
    }
}
