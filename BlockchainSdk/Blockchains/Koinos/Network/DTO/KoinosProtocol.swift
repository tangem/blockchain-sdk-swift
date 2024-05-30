//
//  KoinosProtocol.swift
//  BlockchainSdk
//
//  Created by Aleksei Muraveinik on 21.05.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

enum KoinosProtocol {
    struct Transaction: Equatable, Codable {
        let header: TransactionHeader
        let id: String
        let operations: [Operation]
        let signatures: [String]
    }

    struct TransactionHeader: Equatable, Codable {
        let chainId: String
        let rcLimit: UInt64
        let nonce: String
        let operationMerkleRoot: String
        let payer: String
        let payee: String?
        
        enum CodingKeys: String, CodingKey {
            case chainId = "chain_id"
            case rcLimit = "rc_limit"
            case nonce
            case operationMerkleRoot = "operation_merkle_root"
            case payer
            case payee
        }
    }

    struct Operation: Equatable, Codable {
        let callContract: CallContractOperation
        
        enum CodingKeys: String, CodingKey {
            case callContract = "call_contract"
        }
    }

    struct CallContractOperation: Equatable, Codable {
        let contractIdBase58: String
        let entryPoint: Int
        let argsBase64: String
        
        enum CodingKeys: String, CodingKey {
            case contractIdBase58 = "contract_id"
            case entryPoint = "entry_point"
            case argsBase64 = "args"
        }
    }

    struct TransactionReceipt: Equatable, Codable {
        let id: String
        let payer: String
        let maxPayerRc: UInt64
        let rcLimit: UInt64
        let rcUsed: UInt64
        let diskStorageUsed: String?
        let networkBandwidthUsed: String?
        let computeBandwidthUsed: String?
        let reverted: Bool?
        let events: [EventData]
        
        enum CodingKeys: String, CodingKey {
            case id
            case payer
            case maxPayerRc = "max_payer_rc"
            case rcLimit = "rc_limit"
            case rcUsed = "rc_used"
            case diskStorageUsed = "disk_storage_used"
            case networkBandwidthUsed = "network_bandwidth_used"
            case computeBandwidthUsed = "compute_bandwidth_used"
            case reverted
            case events
        }
    }

    struct BlockHeader: Equatable, Codable {
        let previous: String
        let height: UInt64
        let timestamp: UInt64
        let previousStateMerkleRoot: String
        let transactionMerkleRoot: String
        let signer: String
        let approvedProposals: [String]
        
        enum CodingKeys: String, CodingKey {
            case previous
            case height
            case timestamp
            case previousStateMerkleRoot = "previous_state_merkle_root"
            case transactionMerkleRoot = "transaction_merkle_root"
            case signer
            case approvedProposals = "approved_proposals"
        }
    }

    struct BlockReceipt: Equatable, Codable {
        let id: String
        let height: UInt64
        let diskStorageUsed: String
        let networkBandwidthUsed: String
        let computeBandwidthUsed: String
        let stateMerkleRoot: String
        let events: [EventData]
        let transactionReceipts: [TransactionReceipt]
        
        enum CodingKeys: String, CodingKey {
            case id
            case height
            case diskStorageUsed = "disk_storage_used"
            case networkBandwidthUsed = "network_bandwidth_used"
            case computeBandwidthUsed = "compute_bandwidth_used"
            case stateMerkleRoot = "state_merkle_root"
            case events
            case transactionReceipts = "transaction_receipts"
        }
    }

    struct EventData: Equatable, Codable {
        let sequence: Int?
        let source: String
        let name: String
        let eventData: String
        let impacted: [String]
        
        enum CodingKeys: String, CodingKey {
            case sequence
            case source
            case name
            case eventData = "data"
            case impacted
        }
    }
}
