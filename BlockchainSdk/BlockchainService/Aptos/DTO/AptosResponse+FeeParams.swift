//
//  AptosResponse+FeeParams.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 29.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

extension AptosResponse {
    struct Fee: Decodable {
        let deprioritizedGasEstimate: UInt64
        let gasEstimate: UInt64
        let prioritizedGasEstimate: UInt64
    }
}
