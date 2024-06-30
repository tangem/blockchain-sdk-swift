//
//  KoinosResourceLimitData.swift
//  BlockchainSdk
//
//  Created by Aleksei Muraveinik on 30.06.24.
//

import Foundation

struct KoinosResourceLimitData {
    let diskStorageLimit: UInt64
    let diskStorageCost: UInt64
    let networkBandwidthLimit: UInt64
    let networkBandwidthCost: UInt64
    let computeBandwidthLimit: UInt64
    let computeBandwidthCost: UInt64
}
