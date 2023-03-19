//
//  KaspaNetworkModels.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 13.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

// MARK: - Balance

struct KaspaBalanceResponse: Codable {
    let balance: Int
}

// MARK: - UTXO

struct KaspaUnspentOutputResponse: Codable {
    var outpoint: KaspaOutpoint
    var utxoEntry: KaspaUtxoEntry
}

struct KaspaOutpoint: Codable {
    let transactionId: String
    let index: Int
}

struct  KaspaUtxoEntry: Codable {
    let amount: String
    let scriptPublicKey: KaspaScriptPublicKeyResponse
}

struct KaspaScriptPublicKeyResponse: Codable {
    let scriptPublicKey: String
}

// MARK: - Transaction request

struct KaspaTransactionRequest: Codable {
    let transaction: KaspaTransactionData
}

struct KaspaTransactionData: Codable {
    var version: Int = 0
    let inputs: [KaspaInput]
    let outputs: [KaspaOutput]
    var lockTime: Int = 0
    var subnetworkId: String = "0000000000000000000000000000000000000000"
}

struct KaspaInput: Codable {
    let previousOutpoint: KaspaPreviousOutpoint
    let signatureScript: String
    var sequence: Int = 0
    var sigOpCount: Int = 1
}

struct KaspaPreviousOutpoint: Codable {
    let transactionId: String
    let index: Int
}

struct KaspaOutput: Codable {
    let amount: UInt64
    let scriptPublicKey: KaspaScriptPublicKey
}

struct KaspaScriptPublicKey: Codable {
    let scriptPublicKey: String
    var version: Int = 0
}

// MARK: - Transaction response

struct KaspaTransactionResponse: Codable {
    let transactionId: String
}
