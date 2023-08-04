//
//  TransactionRecord.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 25.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public struct TransactionRecord: Hashable {
    public let hash: String
    public let source: SourceType
    public let destination: DestinationType
    public let fee: Fee
    public let status: TransactionStatus
    public let type: TransactionType
    public let date: Date
    
    public init(
        hash: String,
        source: SourceType,
        destination: DestinationType,
        fee: Fee,
        status: TransactionStatus,
        type: TransactionType,
        date: Date
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
        public let address: String
        public let amount: Decimal
        
        public init(address: String, amount: Decimal) {
            self.address = address
            self.amount = amount
        }
    }
}

// MARK: - Destination

public extension TransactionRecord {
    enum DestinationType: Hashable {
        case single(Destination)
        case multiple([Destination])
    }
    
    struct Destination: Hashable {
        public let address: Address
        public let amount: Decimal
        
        public init(address: TransactionRecord.Destination.Address, amount: Decimal) {
            self.address = address
            self.amount = amount
        }
        
        public enum Address: Hashable {
            case user(String)
            /// Contact address for token-supported blockchains
            case contract(String)
            
            public var string: String {
                switch self {
                case .user(let address):
                    return address
                case .contract(let address):
                    return address
                }
            }
        }
    }
}
