//
//  StakeKitTransaction.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 11.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct StakeKitTransaction: Hashable {
    public let id: String
    public let amount: Amount
    public let fee: Fee
    public let unsignedData: String

    public init(
        id: String,
        amount: Amount,
        fee: Fee,
        unsignedData: String
    ) {
        self.id = id
        self.amount = amount
        self.fee = fee
        self.unsignedData = unsignedData
    }
}

public struct StakeKitTransactionSendResult: Hashable {
    let transaction: StakeKitTransaction
    let result: TransactionSendResult
}
