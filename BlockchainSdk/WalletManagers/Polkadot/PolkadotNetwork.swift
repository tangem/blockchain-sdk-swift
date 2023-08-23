//
//  PolkadotNetwork.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 27.01.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

enum PolkadotNetwork {
    /// Polkadot blockchain for isTestnet = false
    case polkadot(curve: EllipticCurve)
    /// Polkadot blockchain for isTestnet = true
    case westend(curve: EllipticCurve)
    /// Kusama blockchain
    case kusama(curve: EllipticCurve)
    /// Azero blockchain
    case azero(curve: EllipticCurve, testnet: Bool)
    
    init?(blockchain: Blockchain) {
        switch blockchain {
        case .polkadot(let curve, let isTestnet):
            self = isTestnet ? .westend(curve: curve) : .polkadot(curve: curve)
        case .kusama(let curve):
            self = .kusama(curve: curve)
        case .azero(let curve, let isTestnet):
            self = .azero(curve: curve, testnet: isTestnet)
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
        case .azero(_, let isTestnet):
            if isTestnet {
                return [
                    URL(string: "https://rpc.test.azero.dev")!,
                    URL(string: "aleph-zero-testnet-rpc.dwellir.com")!,
                ]
            } else {
                return [
                    URL(string: "https://rpc.azero.dev")!,
                    URL(string: "https://aleph-zero-rpc.dwellir.com")!,
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
        case .polkadot(let curve):
            return Amount(with: .polkadot(curve: curve, testnet: false), value: 1)
        case .kusama(let curve):
            // This value was ALSO found experimentally, just like the one on the Westend.
            // It is different from what official documentation is telling us.
            return Amount(with: .kusama(curve: curve), value: 0.000033333333)
        case .westend(let curve):
            // This value was found experimentally by sending transactions with different values to inactive accounts.
            // This is the lowest amount that activates an account on the Westend network.
            return Amount(with: .polkadot(curve: curve, testnet: true), value: 0.01)
        case .azero(let curve, let isTestnet):
            // Existential deposit - 0.0000000005 Look https://test.azero.dev wallet for example
            return Amount(with: .azero(curve: curve, testnet: isTestnet), value: 0.0000000005)
        }
    }
}
