//
//  AlgorandTransactionHistoryMapper.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 22.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct AlgorandTransactionHistoryMapper {
    private let blockchain: Blockchain
    
    init(blockchain: Blockchain) {
        self.blockchain = blockchain
    }
}

extension AlgorandTransactionHistoryMapper {
    func mapToTransactionRecords(
        _ items: [AlgorandResponse.TransactionHistory.Item],
        amountType: Amount.AmountType,
        currentWalletAddress: String
    ) -> [TransactionRecord] {
        items.map {
            return TransactionRecord(
                hash: $0.id,
                source: .single(
                    .init(address: "qwerty", amount: 123)
                ),
                destination: .single(
                    .init(address: .user("qdkljasldk"), amount: 321)
                ),
                fee: .init(.init(with: blockchain, value: 12)), 
                status: .confirmed,
                isOutgoing: false,
                type: .transfer,
                date: Date()
            )
        }
    }
}
