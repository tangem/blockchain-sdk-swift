//
//  BitcoinNetworkProvider.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 07.04.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Combine

struct BitcoinFee {
    let minimalSatoshiPerByte: Decimal
    let normalSatoshiPerByte: Decimal
    let prioritySatoshiPerByte: Decimal
}

struct BitcoinResponse {
    let balance: Decimal
    let hasUnconfirmed: Bool
    var pendingTxRefs: [PendingTransaction]
    var recentTransactions: [BasicTransactionData]
    let unspentOutputs: [BitcoinUnspentOutput]
    
    init(balance: Decimal, hasUnconfirmed: Bool, pendingTxRefs: [PendingTransaction], unspentOutputs: [BitcoinUnspentOutput]) {
        self.balance = balance
        self.hasUnconfirmed = hasUnconfirmed
        self.pendingTxRefs = pendingTxRefs
        self.recentTransactions = []
        self.unspentOutputs = unspentOutputs
    }
    
//    init(balance: Decimal, hasUnconfirmed: Bool, recentTransactions: [BasicTransactionData], unspentOutputs: [BitcoinUnspentOutput]) {
//        self.balance = balance
//        self.hasUnconfirmed = hasUnconfirmed
//        self.pendingTxRefs = []
//        self.recentTransactions = recentTransactions
//        self.unspentOutputs = unspentOutputs
//    }

}

struct BitcoinTransaction {
    let hash: String
    let isConfirmed: Bool
    let time: Date
    let inputs: [BitcoinTransactionInput]
    let outputs: [BitcoinTransactionOutput]
}

struct BitcoinTransactionInput {
    let unspentOutput: BitcoinUnspentOutput
    let sender: String
    let sequence: Int
}

struct BitcoinTransactionOutput {
    let amount: Decimal
    let recipient: String
}

struct BitcoinUnspentOutput {
    let transactionHash: String
    let outputIndex: Int
    let amount: UInt64
    let outputScript: String
}

extension Array where Element == BitcoinUnspentOutput {
    mutating func appendIfNotContain(_ utxo: BitcoinUnspentOutput) {
        if !contains(where: { $0.transactionHash == utxo.transactionHash }) {
            append(utxo)
        }
    }
}

enum BitcoinNetworkApi {
    case blockchainInfo
	case blockchair
    case blockcypher
}

protocol BitcoinNetworkProvider: AnyObject {
    var host: String { get }
    var supportsRbf: Bool { get }
    func getInfo(addresses: [String]) -> AnyPublisher<[BitcoinResponse], Error>
    func getInfo(address: String) -> AnyPublisher<BitcoinResponse, Error>
    func getFee() -> AnyPublisher<BitcoinFee, Error>
    func send(transaction: String) -> AnyPublisher<String, Error>
    func push(transaction: String) -> AnyPublisher<String, Error>
	func getSignatureCount(address: String) -> AnyPublisher<Int, Error>
}


extension BitcoinNetworkProvider {
    func getInfo(addresses: [String]) -> AnyPublisher<[BitcoinResponse], Error> {
        .multiAddressPublisher(addresses: addresses, requestFactory: {
            self.getInfo(address: $0)
        })
    }
}
