//
//  PendingTransactionRecord.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 04.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

/// Use it in the `Wallet`model like a pending transaction which
public struct PendingTransactionRecord {
    public let hash: String
    public let source: String
    public let destination: String
    public let amount: Amount
    public let fee: Fee
    public let date: Date
    public let isIncoming: Bool
    public let transactionParams: TransactionParams?
    
    public var isDummy: Bool {
        hash == .unknown || source == .unknown || destination == .unknown
    }
    
    public init(
        hash: String,
        source: String,
        destination: String,
        amount: Amount,
        fee: Fee,
        date: Date,
        isIncoming: Bool,
        transactionParams: TransactionParams? = nil
    ) {
        self.hash = hash
        self.source = source
        self.destination = destination
        self.amount = amount
        self.fee = fee
        self.date = date
        self.isIncoming = isIncoming
        self.transactionParams = transactionParams
    }
}

struct PendingTransactionRecordMapper {
    func makeDummy(blockchain: Blockchain) -> PendingTransactionRecord {
        PendingTransactionRecord(
            hash: .unknown,
            source: .unknown,
            destination: .unknown,
            amount: .zeroCoin(for: blockchain),
            fee: Fee(.zeroCoin(for: blockchain)),
            date: Date(),
            isIncoming: false,
            transactionParams: nil
        )
    }
    
    func mapToPendingTransactionRecord(_ pendingTransaction: PendingTransaction, blockchain: Blockchain) -> PendingTransactionRecord {
        PendingTransactionRecord(
            hash: pendingTransaction.hash,
            source: pendingTransaction.source,
            destination: pendingTransaction.destination,
            amount: Amount(with: blockchain, value: pendingTransaction.value),
            fee: Fee(Amount(with: blockchain, value: pendingTransaction.fee ?? 0)),
            date: pendingTransaction.date,
            isIncoming: pendingTransaction.isIncoming,
            transactionParams: pendingTransaction.transactionParams
        )
    }
}
