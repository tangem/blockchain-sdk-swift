//
//  PendingTransaction.swift
//  BlockchainSdk
//
//  Created by Andrew Son on 11/01/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

struct PendingTransaction {
    let hash: String
    var destination: String
    let value: Decimal
    var source: String
    let fee: Decimal?
    let date: Date
    var isAlreadyRbf: Bool
    let sequence: Int
    
    func toBasicTx(userAddress: String) -> BasicTransactionData {
        let isIncoming = userAddress == destination
        return .init(balanceDif: isIncoming ? value : -value, hash: hash, date: date, isConfirmed: false, targetAddress: isIncoming ? source : destination)
    }
}
