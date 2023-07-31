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
    let source: AddressType
    let destination: AddressType
    let amount: Amount
    let fee: Fee
    let status: TransactionStatus
    let type: TransactionType
    let date: Date?
    
    public init(
        hash: String,
        source: AddressType,
        destination: AddressType,
        amount: Amount,
        fee: Fee,
        status: TransactionStatus,
        type: TransactionType,
        date: Date? = nil
    ) {
        self.hash = hash
        self.source = source
        self.destination = destination
        self.amount = amount
        self.fee = fee
        self.status = status
        self.type = type
        self.date = date
    }
}

public extension TransactionRecord {
    enum TransactionType: String, Hashable {
        case send
        case receive
    }
    
    enum AddressType: Hashable {
        case single(_ address: String)
        case multi(_ addresses: [String])
        case contract(_ address: String)
    }
}
