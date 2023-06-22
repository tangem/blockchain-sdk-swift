//
//  PolkadotNetwork.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 27.01.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

enum PolkadotNetwork {
    /// Polkadot blockchain for isTestnet = false
    case polkadot
    /// Polkadot blockchain for isTestnet = true
    case westend
    /// Kusama blockchain
    case kusama
    /// Azero blockchain
    case azero(testnet: Bool)
    
    init?(blockchain: Blockchain) {
        switch blockchain {
        case .polkadot(let isTestnet):
            self = isTestnet ? .westend : .polkadot
        case .kusama:
            self = .kusama
        case .azero(let isTestnet):
            self = .azero(testnet: isTestnet)
        default:
            return nil
        }
    }
    
    // https://wiki.polkadot.network/docs/maintain-endpoints#test-networks
    var urls: [URL] {
        switch self {
        case .polkadot:
            return [
                URL(string: "https://rpc.polkadot.io")!,
                URL(string: "https://polkadot.api.onfinality.io/public-ws")!,
                URL(string: "https://polkadot-rpc.dwellir.com")!,
            ]
        case .kusama:
            return [
                URL(string: "https://kusama-rpc.polkadot.io")!,
                URL(string: "https://kusama.api.onfinality.io/public-ws")!,
                URL(string: "https://kusama-rpc.dwellir.com")!,
            ]
        case .westend:
            return [
                URL(string: "https://westend-rpc.polkadot.io")!,
            ]
        case .azero(let isTestnet):
            if isTestnet {
                return [
                    URL(string: "https://rpc.test.azero.dev")!,
                ]
            } else {
                return [
                    URL(string: "https://rpc.azero.dev")!,
                ]
            }
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
        case .westend, .azero:
            prefixByte = 42
        }
        
        return Data(prefixByte)
    }
}

// https://support.polkadot.network/support/solutions/articles/65000168651-what-is-the-existential-deposit-
extension PolkadotNetwork {
    var existentialDeposit: Amount {
        switch self {
        case .polkadot:
            return Amount(with: .polkadot(testnet: false), value: 1)
        case .kusama:
            // This value was ALSO found experimentally, just like the one on the Westend.
            // It is different from what official documentation is telling us.
            return Amount(with: .kusama, value: 0.000033333333)
        case .westend:
            // This value was found experimentally by sending transactions with different values to inactive accounts.
            // This is the lowest amount that activates an account on the Westend network.
            return Amount(with: .polkadot(testnet: true), value: 0.01)
        case .azero(let isTestnet):
            // Existential deposit - 0.0000000005 Look https://test.azero.dev wallet for example
            return Amount(with: .azero(testnet: isTestnet), value: 0.0000000005)
        }
    }
}
