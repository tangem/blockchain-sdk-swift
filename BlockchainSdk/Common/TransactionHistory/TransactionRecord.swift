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
    let source: SourceType
    let destination: DestinationType
    let fee: Fee
    let status: TransactionStatus
    let type: TransactionType
    let date: Date?
    
    public init(
        hash: String,
        source: SourceType,
        destination: DestinationType,
        fee: Fee,
        status: TransactionStatus,
        type: TransactionType,
        date: Date?
    ) {
        self.hash = hash
        self.source = source
        self.destination = destination
        self.fee = fee
        self.status = status
        self.type = type
        self.date = date
    }
}

// MARK: - TransactionType

public extension TransactionRecord {
    enum TransactionType: String, Hashable {
        case send
        case receive
    }
}

// MARK: - Source

public extension TransactionRecord {
    enum SourceType: Hashable {
        case single(Source)
        case multiple([Source])
    }
    
    struct Source: Hashable {
        let address: String
        let amount: Amount
    }
}

// MARK: - Destination

public extension TransactionRecord {
    enum DestinationType: Hashable {
        case single(Destination)
        case multiple([Destination])
    }
    
    struct Destination: Hashable {
        let address: Address
        let amount: Amount
        
        enum Address: Hashable {
            /// Contact address for token-supported blockchains
            case contract(String)
            case user(String)
        }
    }
}
