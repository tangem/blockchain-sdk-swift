//
//  CryptoAPIsTransaction.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 10.06.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

/// https://developers.cryptoapis.io/technical-documentation/blockchain-data/unified-endpoints/list-unconfirmed-transactions-by-address
struct CryptoAPIsTransaction : Codable, TransactionParams {
    let recipients: [Recipient]
    let senders: [Recipient]
    let timestamp: Date
    let transactionHash: String
    let transactionId: String
    let blockchainSpecific: BlockchainSpecific
}

extension CryptoAPIsTransaction {
    func asPendingTransaction() -> PendingTransaction? {
        guard
            let destination = recipients.first,
            let source = senders.first?.address,
            let vout = blockchainSpecific.vout?.first,
            let isSpent = vout.isSpent,
            let value = Decimal(vout.value ?? "")
        else {
            return nil
        }
        
        return PendingTransaction(
            hash: transactionHash,
            destination: destination.address,
            value: value,
            source: source,
            fee: nil,
            date: timestamp,
            isIncoming: !isSpent,
            transactionParams: self
        )
    }
}

struct BlockchainSpecific : Codable {
    let locktime: Int?
    let size: Int?
    let vSize: Int?
    let version: Int?
    let vin: [Vin]?
    let vout: [Vout]?
}

struct Vin: Codable {
    let addresses: [String]?
    let scriptSig: ScriptSig?
    let sequence: String?
    let txid: String?
    let txinwitness: [String]?
    let value: String?
    let vout: Int?
}

struct Vout: Codable {
    let isSpent: Bool?
    let scriptPubKey: ScriptPubKey?
    let value: String?
}

struct ScriptPubKey: Codable {
    let addresses: [String]?
    let asm: String?
    let hex: String?
    let reqSigs: Int?
    let type: String?
}

struct ScriptSig: Codable {
    let asm: String?
    let hex: String?
    let type: String?
}

struct Recipient: Codable {
    let address: String
    let amount: String
}
