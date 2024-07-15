//
//  StakeKitTransaction.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 11.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct StakeKitTransaction {
    public let amount: Amount
    public let fee: Fee
    public let sourceAddress: String
    public let unsignedData: String

    public init(
        amount: Amount,
        fee: Fee,
        sourceAddress: String,
        unsignedData: String
    ) {
        self.amount = amount
        self.fee = fee
        self.sourceAddress = sourceAddress
        self.unsignedData = unsignedData
    }
}
