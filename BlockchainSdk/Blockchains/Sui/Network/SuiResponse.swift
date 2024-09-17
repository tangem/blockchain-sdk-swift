//
// SuiResponse.swift
// BlockchainSdk
//
// Created by Sergei Iakovlev on 30.08.2024
// Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

//MARK: Balance
public struct SuiGetCoins: Codable {
    public struct Coin: Codable, Hashable {
        public var coinType: String
        public var coinObjectId: String
        public var version: String
        public var digest: String
        public var balance: String
        public var previousTransaction: String
        
        public func hash(into hasher: inout Hasher) {
            digest.hash(into: &hasher)
        }
    }

    public var hasNextPage: Bool
    public var data: [Coin]
    public var nextCursor: String?
}


//MARK: GasPrice
public typealias SuiReferenceGasPrice = String

//MARK: ExecuteTransaction
public struct SuiExecuteTransaction: Codable {
    public var digest: String
}

//MARK: DryRunTransaction
public struct SuiInspectTransaction: Codable {
    public var effects: SuiTransaction.SuiTransactionEffects
    public var input: SuiTransaction.SuiTransactionData
}

public struct SuiTransaction: Codable {
    
    //SubTypes
    public struct Transaction: Codable {
        public struct SuiTransactionInput: Codable {
            public var type: String
            //
            public var valueType: String?
            public var value: String?
            //
            public var objectType: String?
            public var objectId: String?
            public var version: String?
            public var digest: String?
        }
        
        public struct SuiTransactions: Codable {
            
        }
        
        public var kind: String
        public var inputs: [SuiTransactionInput]
    }

    public struct GasData: Codable {
        public struct Payment: Codable {
            public var objectId: String
            public var version: UInt64
            public var digest: String
        }
        
        public var owner: String
        public var price: String
        public var budget: String
        public var payment: [Payment]
    }
    
    public struct SuiTransactionData: Codable {
        public var messageVersion: String
        public var transaction: SuiTransaction.Transaction
        public var sender: String
        public var gasData: GasData
    }
    
    public struct SuiTransactionGasUsed: Codable {
        public var computationCost: String
        public var storageCost: String
        public var storageRebate: String
        public var nonRefundableStorageFee: String
    }
    
    public struct SuiTransactionEffects: Codable {
        public struct Status: Codable {
            public var status: String
        }
        
        public var messageVersion: String
        public var status: Status
        public var gasUsed: SuiTransactionGasUsed
        public var transactionDigest: String
        
    }
    
    // Body
    public var data: SuiTransactionData
    public var txSignatures: [String]
    public var rawTransaction: String
    public var effects: SuiTransactionEffects
}
