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

struct BlockcypherFullAddressResponse<EndpointTx: Codable>: Codable {
    let address: String?
    let balance: Int?
    let unconfirmedBalance: Int?
    let nTx: Int?
    let unconfirmedNTx: Int?
    let txs: [EndpointTx]?
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

protocol BlockcypherPendingTxConvertible {
    associatedtype Input: BlockcypherInput
    associatedtype Output: BlockcypherOutput
    var hash: String { get }
    var fees: Decimal { get }
    var received: Date { get }
    var inputs: [Input] { get }
    var outputs: [Output] { get }
    
    func pendingTx(for sourceAddress: String, decimalValue: Decimal) -> PendingTransaction
}

extension BlockcypherPendingTxConvertible {
    func pendingTx(for sourceAddress: String, decimalValue: Decimal) -> PendingTransaction {
        var source: String = .unknown
        var destination: String = .unknown
        var value: UInt64 = 0
        
        if let txSource = inputs.first(where: { $0.addresses.contains(sourceAddress) } ), let txDestination = outputs.first(where: { !$0.addresses.contains(sourceAddress) } ) {
            destination = txDestination.addresses.first ?? .unknown
            source = txSource.addresses.first ?? .unknown
            value = txDestination.value
        } else if let txDestination = outputs.first(where: { $0.addresses.contains(sourceAddress) } ), let txSource = inputs.first(where: { !$0.addresses.contains(sourceAddress) } ) {
            destination = txDestination.addresses.first ?? .unknown
            source = txSource.addresses.first ?? .unknown
            value = txDestination.value
        }
        
        return PendingTransaction(hash: hash,
                                  destination: destination,
                                  value: Decimal(value) / decimalValue,
                                  source: source,
                                  fee: fees / decimalValue,
                                  date: received)
    }
}

protocol BlockcypherInput {
    var addresses: [String] { get }
}

protocol BlockcypherOutput {
    var value: UInt64 { get }
    var addresses: [String] { get }
}

struct BlockcypherBitcoinTx: Codable, BlockcypherPendingTxConvertible {
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
    
    func btcTx(for sourceAddress: String) -> BtcTx? {
        var txOutputIndex: Int = -1
        guard
            outputs.enumerated().contains(where: {
                guard
                    $0.element.addresses.contains(sourceAddress),
                    $0.element.spentBy == nil
                else { return false }
                
                txOutputIndex = $0.offset
                return true
            }),
            txOutputIndex >= 0
        else {
            return nil
        }
        
        let script = outputs[txOutputIndex].script
        let value = outputs[txOutputIndex].value
        
        let btc = BtcTx(tx_hash: hash, tx_output_n: txOutputIndex, value: value, script: script)
        return btc
    }
}

struct BlockcypherTxInput: Codable, BlockcypherInput {
    let prevHash: String
    let outputValue: UInt64
    let addresses: [String]
    let sequence: UInt64
    let scriptType: String
    let witness: [String]?
    let script: String?
}

struct BlockcypherTxOutput: Codable, BlockcypherOutput {
    let value: UInt64
    let script: String
    let addresses: [String]
    let scriptType: String
    let spentBy: String?
}
