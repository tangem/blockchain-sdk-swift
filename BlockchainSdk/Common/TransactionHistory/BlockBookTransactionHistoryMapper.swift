//
//  BlockBookTransactionHistoryMapper.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 17.08.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
protocol BlockBookTransactionHistoryMapper {
    func mapToTransactionRecords(_ response: BlockBookAddressResponse, amountType: Amount.AmountType) -> [TransactionRecord]
}
