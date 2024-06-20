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
        
        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: KoinosChain.ResourceLimitData.CodingKeys.self)
            guard let diskStorageLimit = UInt64(try container.decode(String.self, forKey: KoinosChain.ResourceLimitData.CodingKeys.diskStorageLimit)),
                  let diskStorageCost = UInt64(try container.decode(String.self, forKey: KoinosChain.ResourceLimitData.CodingKeys.diskStorageCost)),
                  let networkBandwidthLimit = UInt64(try container.decode(String.self, forKey: KoinosChain.ResourceLimitData.CodingKeys.networkBandwidthLimit)),
                  let networkBandwidthCost = UInt64(try container.decode(String.self, forKey: KoinosChain.ResourceLimitData.CodingKeys.networkBandwidthCost)),
                  let computeBandwidthLimit = UInt64(try container.decode(String.self, forKey: KoinosChain.ResourceLimitData.CodingKeys.computeBandwidthLimit)),
                  let computeBandwidthCost = UInt64(try container.decode(String.self, forKey: KoinosChain.ResourceLimitData.CodingKeys.computeBandwidthCost)) 
            else {
                throw WalletError.failedToParseNetworkResponse
            }
            
            self.diskStorageLimit = diskStorageLimit
            self.diskStorageCost = diskStorageCost
            self.networkBandwidthLimit = networkBandwidthLimit
            self.networkBandwidthCost = networkBandwidthCost
            self.computeBandwidthLimit = computeBandwidthLimit
            self.computeBandwidthCost = computeBandwidthCost
        }
    }
}
