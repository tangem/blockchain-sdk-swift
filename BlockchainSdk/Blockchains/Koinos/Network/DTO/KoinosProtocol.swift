//
//  KoinosProtocol.swift
//  BlockchainSdk
//
//  Created by Aleksei Muraveinik on 21.05.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

enum KoinosProtocol {
    struct Transaction: Equatable, Encodable {
        let header: TransactionHeader
        let id: String
        let operations: [Operation]
        let signatures: [String]
    }

    struct TransactionHeader: Equatable, Encodable {
        let chainId: String
        let rcLimit: UInt64
        let nonce: String
        let operationMerkleRoot: String
        let payer: String
        let payee: String?
    }

    struct Operation: Equatable, Encodable {
        let callContract: CallContractOperation
    }

    struct CallContractOperation: Equatable, Encodable {
        let contractId: String
        let entryPoint: Int
        let args: String
    }

    struct TransactionReceipt: Equatable, Decodable {
        let id: String
        let payer: String
        let maxPayerRc: String
        let rcLimit: String
        let rcUsed: String
        let diskStorageUsed: String?
        let networkBandwidthUsed: String?
        let computeBandwidthUsed: String?
        let reverted: Bool?
        let events: [EventData]
    }

    struct BlockHeader: Equatable, Decodable {
        let previous: String
        let height: UInt64
        let timestamp: UInt64
        let previousStateMerkleRoot: String
        let transactionMerkleRoot: String
        let signer: String
        let approvedProposals: [String]
    }

    struct BlockReceipt: Equatable, Decodable {
        let id: String
        let height: UInt64
        let diskStorageUsed: String
        let networkBandwidthUsed: String
        let computeBandwidthUsed: String
        let stateMerkleRoot: String
        let events: [EventData]
        let transactionReceipts: [TransactionReceipt]
    }

    struct EventData: Equatable, Decodable {
        let sequence: Int?
        let source: String
        let name: String
        let data: String
        let impacted: [String]
    }
    
    struct ResourceLimitData: Decodable {
        let diskStorageLimit: String
        let diskStorageCost: String
        let networkBandwidthLimit: String
        let networkBandwidthCost: String
        let computeBandwidthLimit: String
        let computeBandwidthCost: String
    }
}
