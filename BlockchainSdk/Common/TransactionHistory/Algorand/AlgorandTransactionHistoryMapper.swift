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
    
    private var decimalValue: Decimal {
        blockchain.decimalValue
    }
    
    init(blockchain: Blockchain) {
        self.blockchain = blockchain
    }
}

extension AlgorandTransactionHistoryMapper {
    func mapToTransactionRecords(
        _ response: AlgorandResponse.TransactionHistory,
        amountType: Amount.AmountType
    ) -> [TransactionRecord] {
        return []
    }
}
