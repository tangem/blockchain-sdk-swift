//
//  PendingTransactionRecordMapper.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 05.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

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
