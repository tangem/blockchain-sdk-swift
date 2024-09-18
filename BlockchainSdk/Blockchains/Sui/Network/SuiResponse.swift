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
        public let coinType: String
        public let coinObjectId: String
        public let version: String
        public let digest: String
        public let balance: String
        public let previousTransaction: String
        
        public func hash(into hasher: inout Hasher) {
            digest.hash(into: &hasher)
        }
    }

    public let hasNextPage: Bool
    public let data: [Coin]
    public let nextCursor: String?
}


//MARK: GasPrice
public typealias SuiReferenceGasPrice = String

//MARK: ExecuteTransaction
public struct SuiExecuteTransaction: Codable {
    public let digest: String
}

//MARK: DryRunTransaction
public struct SuiInspectTransaction: Codable {
    public let effects: SuiTransaction.SuiTransactionEffects
    public let input: SuiTransaction.SuiTransactionData
}

public struct SuiTransaction: Codable {
    
    //SubTypes
    public struct Transaction: Codable {
        public struct SuiTransactionInput: Codable {
            public let type: String
            //
            public let valueType: String?
            public let value: String?
            //
            public let objectType: String?
            public let objectId: String?
            public let version: String?
            public let digest: String?
        }
        
        public struct SuiTransactions: Codable {
            
        }
        
        public let kind: String
        public let inputs: [SuiTransactionInput]
    }

    public struct GasData: Codable {
        public struct Payment: Codable {
            public let objectId: String
            public let version: UInt64
            public let digest: String
        }
        
        public let owner: String
        public let price: String
        public let budget: String
        public let payment: [Payment]
    }
    
    public struct SuiTransactionData: Codable {
        public let messageVersion: String
        public let transaction: SuiTransaction.Transaction
        public let sender: String
        public let gasData: GasData
    }
    
    public struct SuiTransactionGasUsed: Codable {
        public let computationCost: String
        public let storageCost: String
        public let storageRebate: String
        public let nonRefundableStorageFee: String
    }
    
    public struct SuiTransactionEffects: Codable {
        public struct Status: Codable {
            public let status: String
        }
        
        public let messageVersion: String
        public let status: Status
        public let gasUsed: SuiTransactionGasUsed
        public let transactionDigest: String
        
    }
    
    // Body
    public let data: SuiTransactionData
    public let txSignatures: [String]
    public let rawTransaction: String
    public let effects: SuiTransactionEffects
}
