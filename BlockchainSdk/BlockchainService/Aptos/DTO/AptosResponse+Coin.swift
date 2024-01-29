//
//  AptosResponse+Coin.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 26.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

/// https://aptos.dev/concepts/resources#resources-vs-instances
extension AptosResponse {
    struct CoinStore: Decodable {
        let coin: Coin
    }
    
    struct Coin: Decodable {
        let value: UInt64
    }
}
