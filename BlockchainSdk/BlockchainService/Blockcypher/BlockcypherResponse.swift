//
//  BlockcypherResponse.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 07.04.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

struct BlockcypherAddressResponse : Codable {
    let address: String?
    let balance: Int?
    let unconfirmed_balance: Int?
    let txrefs: [BlockcypherTxref]?
    let unconfirmed_txrefs: [BlockcypherTxref]?
}

struct BlockcypherFullAddressResponse: Codable {
    let address: String?
    let balance: Int?
    let unconfirmedBalance: Int?
    let nTx: Int?
    let unconfirmedNTx: Int?
    let txs: [BlockcypherTx]?
}

struct BlockcypherTxref: Codable {
    let tx_hash: String?
    let tx_output_n: Int?
    let value: Int64?
    let confirmations: Int64?
    let script: String?
}

struct BlockcypherFeeResponse: Codable {
    let low_fee_per_kb: Int64?
    let medium_fee_per_kb: Int64?
    let high_fee_per_kb: Int64?
}

struct BlockcypherTx: Codable {
    let blockIndex: Int64
    let hash: String
    let addresses: [String]
    let total: Decimal
    let fees: Decimal
    let size: Int64
    let confirmations: Int
    let received: Date
    let inputs: [BlockcypherTxInput]
    let outputs: [BlockcypherTxOutput]
    
    func pendingBtxTx(sourceAddress: String, decimalValue: Decimal) -> PendingBtcTx {
        var destination: String = .unknown
        var source: String = .unknown
        var value: UInt64 = 0
        
        if let input = inputs.first(where: { $0.addresses.contains(sourceAddress) } ), let output = outputs.first(where: { !$0.addresses.contains(sourceAddress) } ) {
            destination = output.addresses.first ?? .unknown
            source = input.addresses.first ?? .unknown
            value = output.value
        } else if let input = outputs.first(where: { $0.addresses.contains(sourceAddress) } ), let output = inputs.first(where: { !$0.addresses.contains(sourceAddress) } ) {
            destination = input.addresses.first ?? .unknown
            source = output.addresses.first ?? .unknown
            value = input.value
        }
        
        return PendingBtcTx(hash: hash,
                            destination: destination,
                            value: Decimal(value) / decimalValue,
                            source: source,
                            fee: fees / decimalValue,
                            date: received)
    }
}

struct BlockcypherTxInput: Codable {
    let prevHash: String
    let outputValue: UInt64
    let addresses: [String]
    let sequence: UInt64
    let scriptType: String
    let witness: [String]?
    let script: String?
}

struct BlockcypherTxOutput: Codable {
    let value: UInt64
    let script: String
    let addresses: [String]
    let scriptType: String
    let spentBy: String?
}
