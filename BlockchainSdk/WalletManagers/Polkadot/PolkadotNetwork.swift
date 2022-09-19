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
    var addressPrefix: Data {
        let prefixByte: UInt8
        
        switch self {
        case .polkadot:
            prefixByte = 0
        case .kusama:
            prefixByte = 2
        case .westend:
            prefixByte = 42
        }
        
        return Data(prefixByte)
    }
    
    // https://support.polkadot.network/support/solutions/articles/65000168651-what-is-the-existential-deposit-
    var existentialDeposit: Amount {
        switch self {
        case .polkadot:
            return Amount(with: blockchain, value: 1)
        case .kusama:
            return Amount(with: blockchain, value: 0.0000333333)
        case .westend:
            // This value was found experimentally by sending transactions with different values to inactive accounts.
            // This is the lowest amount that activates an account on the Westend network.
            return Amount(with: blockchain, value: 0.01)
        }
    }
}
