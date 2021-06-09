//
//  BlockcypherResponse.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 07.04.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import BitcoinCore

struct BlockcypherAddressResponse : Codable {
    let address: String?
    let balance: Int?
    let unconfirmedBalance: Int?
    let txrefs: [BlockcypherTxref]?
    let unconfirmedTxrefs: [BlockcypherTxref]?
    
    private enum CodingKeys: String, CodingKey {
        case address, balance, txrefs
        case unconfirmedBalance = "unconfirmed_balance", unconfirmedTxrefs = "unconfirmed_txrefs"
    }
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
    let hash: String?
    let outputIndex: Int?
    let value: Int64?
    let confirmations: Int64?
    let outputScript: String?
    let spent: Bool?
    let received: String?
    
    private enum CodingKeys: String, CodingKey {
        case hash = "tx_hash", outputIndex = "tx_output_n", outputScript = "script"
        case value, confirmations, spent, received
    }
}

extension BlockcypherTxref {
    func toUnspentOutput() -> BitcoinUnspentOutput? {
        guard
            let hash = hash,
            let outputIndex = outputIndex,
            let value = value,
            let script = outputScript,
            spent == false
        else { return nil }
        
        return BitcoinUnspentOutput(transactionHash: hash, outputIndex: outputIndex, amount: UInt64(value), outputScript: script)
    }
}

extension Array where Element == BlockcypherTxref {
    func toBasicTxDataArray(isConfirmed: Bool, decimals: Decimal) -> [BasicTransactionData] {
        var txsDict = [String: BasicTransactionData]()
        forEach {
            let valueDecimal = Decimal($0.value ?? 0) / decimals
            var balanceDif = $0.outputIndex == -1 ? -valueDecimal : valueDecimal
            var receivedDate: Date?
            if let receivedStr = $0.received,
               let date = DateFormatter.iso8601withFractionalSeconds.date(from: receivedStr) ?? DateFormatter.iso8601.date(from: receivedStr) {
                receivedDate = date
            }
            
            let hash = $0.hash ?? ""
            if let tx = txsDict[hash] {
                balanceDif += tx.balanceDif
            }
            
            let tx = BasicTransactionData(balanceDif: balanceDif, hash: hash, date: receivedDate, isConfirmed: isConfirmed, targetAddress: nil)
            
            txsDict[hash] = tx
        }
        
        return txsDict.map { $0.value }
    }
}

struct BlockcypherFeeResponse: Codable {
    let low_fee_per_kb: Int64?
    let medium_fee_per_kb: Int64?
    let high_fee_per_kb: Int64?
}

protocol BlockcypherPendingTxConvertible {
    var hash: String { get }
    var fees: Decimal { get }
    var received: Date { get }
    var inputs: [BlockcypherInput] { get }
    var outputs: [BlockcypherOutput] { get }

    func toPendingTx(userAddress: String, decimalValue: Decimal) -> PendingTransaction
}

extension BlockcypherPendingTxConvertible {
    func toPendingTx(userAddress: String, decimalValue: Decimal) -> PendingTransaction {
        var source: String = .unknown
        var destination: String = .unknown
        var value: UInt64 = 0
        var isIncoming: Bool = false

        if let txSource = inputs.first(where: { $0.addresses?.contains(userAddress) ?? false } ), let txDestination = outputs.first(where: { !($0.addresses?.contains(userAddress) ?? false) } ) {
            destination = txDestination.addresses?.first ?? .unknown
            source = userAddress
            value = txDestination.value ?? 0
        } else if let txDestination = outputs.first(where: { $0.addresses?.contains(userAddress) ?? false } ), let txSource = inputs.first(where: { !($0.addresses?.contains(userAddress) ?? false) } ) {
            isIncoming = true
            destination = userAddress
            source = txSource.addresses?.first ?? .unknown
            value = txDestination.value ?? 0
        }

        return PendingTransaction(hash: hash,
                                  destination: destination,
                                  value: Decimal(value) / decimalValue,
                                  source: source,
                                  fee: fees / decimalValue,
                                  date: received,
                                  sequence: inputs.first?.sequence ?? SequenceValues.default.rawValue,
                                  isIncoming: isIncoming)
    }
}

struct BlockcypherTransaction: Codable {
    let block: Int?
    let hash: String?
    let received: String?
    let confirmed: String?
    let inputs: [BlockcypherInput]?
    let outputs: [BlockcypherOutput]?
}

struct BlockcypherInput: Codable {
    let transactionHash: String?
    let index: Int?
    let value: UInt64?
    let addresses: [String]?
    let sequence: Int?
    let script: String?
    
    private enum CodingKeys: String, CodingKey {
        case transactionHash = "prev_hash", value = "output_value", index = "output_index"
        case addresses, sequence, script
    }
    
    func toBtcInput() -> BitcoinTransactionInput? {
        guard
            let hash = transactionHash,
            let index = index,
            let amount = value,
            let script = script,
            let sender = addresses?.first,
            let sequence = sequence
        else { return nil }
        
        let output = BitcoinUnspentOutput(transactionHash: hash, outputIndex: index, amount: amount, outputScript: script)
        return BitcoinTransactionInput(unspentOutput: output,
                                       sender: sender,
                                       sequence: sequence)
    }
}

struct BlockcypherOutput: Codable {
    let value: UInt64?
    let script: String?
    let addresses: [String]?
    let scriptType: String?
    let spentBy: String?
    
    func toBtcOutput(decimals: Decimal) -> BitcoinTransactionOutput? {
        guard
            let amount = value,
            let recipient = addresses?.first
        else { return nil }
        
        return BitcoinTransactionOutput(amount: Decimal(amount) / decimals,
                                        recipient: recipient)
    }
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
    let doubleSpendTx: String?
    let optInRbf: Bool?
    let inputs: [BlockcypherInput]
    let outputs: [BlockcypherOutput]
    
    func findUnspentOutput(for sourceAddress: String) -> BitcoinUnspentOutput? {
        var txOutputIndex: Int = -1
        guard
            outputs.enumerated().contains(where: {
                guard
                    $0.element.addresses?.contains(sourceAddress) ?? false,
                    $0.element.spentBy == nil
                else { return false }
                
                txOutputIndex = $0.offset
                return true
            }),
            txOutputIndex >= 0,
            let script = outputs[txOutputIndex].script,
            let value = outputs[txOutputIndex].value
        else {
            return nil
        }
        
        let btc = BitcoinUnspentOutput(transactionHash: hash, outputIndex: txOutputIndex, amount: value, outputScript: script)
        return btc
    }
}

//struct BlockcypherTxInput: Codable, BlockcypherInput {
//    let transactionHash: String?
//    let value: UInt64?
//    let addresses: [String]
//    let sequence: Int
//    let witness: [String]?
//    let script: String?
//
//    private enum CodingKeys: String, CodingKey {
//        case transactionHash = "prev_hash", value = "output_value"
//        case addresses, sequence, witness, script
//    }
//}
