//
//  PolkadotNetwork.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 27.01.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

enum PolkadotNetwork: CaseIterable {
    case polkadot
    case kusama
    case westend
    
    var blockchain: Blockchain {
        switch self {
        case .polkadot:
            return .polkadot(testnet: false)
        case .kusama:
            return .kusama
        case .westend:
            return .polkadot(testnet: true)
        }
    }
    
    // https://wiki.polkadot.network/docs/maintain-endpoints#test-networks
    var url: URL {
        switch self {
        case .polkadot:
            return URL(string: "https://rpc.polkadot.io")!
        case .kusama:
            return URL(string: "https://kusama-rpc.polkadot.io")!
        case .westend:
            return URL(string: "https://westend-rpc.polkadot.io")!
        }
    }
    
    // https://wiki.polkadot.network/docs/build-protocol-info#addresses
    var addressPrefix: UInt8 {
        switch self {
        case .polkadot:
            return 0
        case .kusama:
            return 2
        case .westend:
            return 42
        }
    }
}
