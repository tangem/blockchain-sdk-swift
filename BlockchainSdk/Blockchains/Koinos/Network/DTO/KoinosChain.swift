//
//  KoinosChain.swift
//  BlockchainSdk
//
//  Created by Aleksei Muraveinik on 27.05.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

enum KoinosChain {
    struct ResourceLimitData: Codable {
        let diskStorageLimit: UInt64
        let diskStorageCost: UInt64
        let networkBandwidthLimit: UInt64
        let networkBandwidthCost: UInt64
        let computeBandwidthLimit: UInt64
        let computeBandwidthCost: UInt64
    }
}
