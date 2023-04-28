//
//  TWCoin+.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 28.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import WalletCore

extension CoinType {
    
    /// Сonstructor that maps the sdk blockchain type into the TrustWallet coin type
    init(_ blockchain: Blockchain) throws {
        switch blockchain {
        case .bitcoin:
            self = .bitcoin
        case .litecoin:
            self = .litecoin
        case .stellar:
            self = .stellar
        case .ethereum:
            self = .ethereum
        case .ethereumClassic:
            self = .ethereumClassic
        case .bitcoinCash:
            self = .bitcoinCash
        case .binance:
            self = .binance
        case .tezos:
            self = .tezos
        case .xrp:
            self = .xrp
        case .tron:
            self = .tron
        case .ton:
            self = .ton
        case .solana:
            self = .solana
        case .polkadot:
            self = .polkadot
        case .kusama:
            self = .kusama
        case .bsc:
            self = .smartChain
        case .cardano:
            self = .cardano
        case .polygon:
            self = .polygon
        case .ravencoin:
            self = .ravencoin
        case .cosmos:
            self = .cosmos
        case .ethereumPoW, .ethereumFair, .rsk, .ducatus, .dogecoin, .avalanche, .fantom, .arbitrum, .dash, .gnosis, .optimism, .saltPay, .kava, .kaspa:
            // Blockchains that are not in WalletCore yet
            throw NSError()
        }
    }
    
}
