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
        case .tron:
            self = .tron
        case .ton:
            self = .ton
        default:
            throw NSError()
        }
    }
    
}

extension CoinType {
    
}
