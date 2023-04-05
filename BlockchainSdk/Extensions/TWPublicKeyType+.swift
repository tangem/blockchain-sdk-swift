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
        case .bitcoin:
            self = PublicKeyType.secp256k1
        case .ethereum:
            self = PublicKeyType.secp256k1Extended
        case .litecoin:
            self = PublicKeyType.secp256k1
        case .stellar:
            self = PublicKeyType.ed25519
        case .xrp(let curve):
            switch curve {
            case .secp256k1:
                self = PublicKeyType.secp256k1
            case .ed25519:
                self = PublicKeyType.ed25519
            default:
                throw NSError()
            }
        case .ton:
            self = .ed25519
        case .cardano:
            self = .ed25519Cardano
        case .binance:
            self = .secp256k1
        case .bsc:
            self = .secp256k1Extended
        case .solana:
            self = .ed25519
        case .polkadot:
            self = .ed25519
        case .kusama:
            self = .ed25519
        case .tron:
            self = .secp256k1Extended
        case .tezos(let curve):
            switch curve {
            case .ed25519:
                self = .ed25519
            default:
                throw NSError()
            }
        case .polygon:
            self = .secp256k1Extended
        case .dash:
            self = .secp256k1
        case .dogecoin:
            self = .secp256k1
        default:
            throw NSError()
        }
    }
    
}
