//
//  TWPublicKeyType+.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 30.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import WalletCore

extension PublicKeyType {
    
    /// Сonstructor that maps the sdk blockchain type into the TrustWallet public key type
    init(_ blockchain: Blockchain) throws {
        switch blockchain {
        case .bitcoin, .litecoin, .binance, .dash, .dogecoin, .bitcoinCash, .ravencoin, .cosmos, .terraV1, .terraV2:
            self = PublicKeyType.secp256k1
        case .ethereum, .bsc, .tron, .polygon, .arbitrum, .avalanche, .ethereumClassic, .optimism, .fantom, .kava:
            self = PublicKeyType.secp256k1Extended
        case .stellar, .ton, .solana, .polkadot, .kusama:
            self = PublicKeyType.ed25519
        case .cardano(let extended):
            self = extended ? PublicKeyType.ed25519Cardano : .ed25519
        case .xrp(let curve):
            switch curve {
            case .secp256k1:
                self = PublicKeyType.secp256k1
            case .ed25519, .ed25519_slip0010:
                self = PublicKeyType.ed25519
            default:
                throw NSError()
            }
        case .tezos(let curve):
            switch curve {
            case .ed25519, .ed25519_slip0010:
                self = .ed25519
            default:
                throw NSError()
            }
        default:
            throw NSError()
        }
    }
    
}
