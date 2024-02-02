//
//  TWPublicKeyType+.swift
//  BlockchainSdkTests
//
//  Created by skibinalexander on 30.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import WalletCore
import BlockchainSdk

extension PublicKeyType {
    /// Сonstructor that maps the sdk blockchain type into the TrustWallet public key type
    /// - Warning: Not for production use, use only for unit tests.
    init(_ blockchain: BlockchainSdk.Blockchain) throws {
        switch blockchain {
        case .bitcoin,
                .litecoin,
                .binance,
                .dash,
                .dogecoin,
                .bitcoinCash,
                .ravencoin,
                .cosmos,
                .terraV1,
                .terraV2:
            self = PublicKeyType.secp256k1
        case .ethereum,
                .bsc,
                .tron,
                .polygon,
                .arbitrum,
                .avalanche,
                .ethereumClassic,
                .optimism,
                .fantom,
                .kava,
                .decimal,
                .veChain,
                .xdc:
            self = PublicKeyType.secp256k1Extended
        case .stellar,
                .ton,
                .solana,
                .polkadot,
                .kusama,
                .near, 
                .algorand,
                .hedera:
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
                throw NSError(
                    domain: "BlockchainSDKTests",
                    code: -1,
                    userInfo: [
                        NSLocalizedDescriptionKey: "Unsupported curve \"\(blockchain.curve)\" for blockchain \"\(blockchain)\"",
                    ]
                )
            }
        case .tezos(let curve):
            switch curve {
            case .ed25519, .ed25519_slip0010:
                self = .ed25519
            default:
                throw NSError(
                    domain: "BlockchainSDKTests",
                    code: -1,
                    userInfo: [
                        NSLocalizedDescriptionKey: "Unsupported curve \"\(blockchain.curve)\" for blockchain \"\(blockchain)\"",
                    ]
                )
            }
        case .ethereumPoW,
                .ethereumFair,
                .rsk,
                .ducatus,
                .azero,
                .gnosis,
                .kaspa,
                .cronos,
                .telos,
                .octa,
                .chia:
            throw NSError(
                domain: "BlockchainSDKTests",
                code: -1,
                userInfo: [
                    NSLocalizedDescriptionKey: "Unsupported blockchain \"\(blockchain)\"",
                ]
            )
        }
    }
}
