//
//  TransactionHistoryMapper.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 17.08.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

protocol TransactionHistoryMapper {
    func mapToTransactionRecords(_ response: BlockBookAddressResponse) -> [TransactionRecord]
}
