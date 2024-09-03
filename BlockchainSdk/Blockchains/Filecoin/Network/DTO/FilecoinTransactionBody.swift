//
//  FilecoinTransactionBody.swift
//  BlockchainSdk
//
//  Created by Aleksei Muraveinik on 27.08.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct FilecoinTransactionBody: Codable, Equatable {
    let sourceAddress: String
    let destinationAddress: String
    let amount: String
    let nonce: UInt64
    let gasUnitPrice: String?
    let gasLimit: UInt64?
    let gasPremium: String?
    
    enum CodingKeys: String, CodingKey {
        case sourceAddress = "From"
        case destinationAddress = "To"
        case amount = "Value"
        case nonce = "Nonce"
        case gasUnitPrice = "GasFeeCap"
        case gasLimit = "GasLimit"
        case gasPremium = "GasPremium"
    }
}
