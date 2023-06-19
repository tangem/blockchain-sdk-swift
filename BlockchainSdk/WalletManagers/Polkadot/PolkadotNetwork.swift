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
    case azero
    
    init?(blockchain: Blockchain) {
        switch blockchain {
        case .polkadot(let isTestnet):
            if isTestnet {
                self = .westend
            } else {
                self = .polkadot
            }
        case .kusama:
            self = .kusama
        case .azero:
            self = .azero
        default:
            return nil
        }
    }
    
    // https://wiki.polkadot.network/docs/maintain-endpoints#test-networks
    func urls(isTestnet: Bool) -> [URL] {
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
        case .azero:
            if isTestnet {
                return [
                    URL(string: "https://rpc.test.azero.dev")!
                ]
            } else {
                return [
                    URL(string: "https://rpc.azero.dev")!
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
