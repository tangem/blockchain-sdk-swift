//
//  CryptoAPIsFee.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 14.06.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

/// https://developers.cryptoapis.io/technical-documentation/blockchain-data/unified-endpoints/get-fee-recommendations
struct CryptoAPIsFee: Codable {
    let unit: String
    let fast: String
    let slow: String
    let standard: String
    
    /// Represents the fee cushion multiplier used to multiply the base fee.
    let feeMultiplier: String?
}
