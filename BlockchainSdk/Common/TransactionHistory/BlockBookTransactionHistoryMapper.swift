//
//  BlockBookTransactionHistoryMapper.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 17.08.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

// TODO: Andrey Fedorov - Replace with `TransactionHistoryMapper` (IOS-6341)
@available(iOS 13.0, *)
@available(*, deprecated, message: "Use `TransactionHistoryMapper` interface instead")
protocol BlockBookTransactionHistoryMapper {
    func mapToTransactionRecords(_ response: BlockBookAddressResponse, amountType: Amount.AmountType) -> [TransactionRecord]
}
