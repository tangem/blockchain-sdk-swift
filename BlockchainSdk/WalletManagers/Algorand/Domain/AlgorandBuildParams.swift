//
//  AlgorandBuildParams.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 17.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

/// This model use only for domain build transaction
struct AlgorandBuildParams {
    let genesisId: String
    let genesisHash: String
    let firstRound: UInt64
    let lastRound: UInt64
    let nonce: String?
}
