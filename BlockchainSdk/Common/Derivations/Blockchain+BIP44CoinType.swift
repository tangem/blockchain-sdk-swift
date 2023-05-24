//
//  Blockchain+BIP44CoinType.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 24.05.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

extension Blockchain {
    /// Source: https://github.com/satoshilabs/slips/blob/master/slip-0044.md
    public var bip44CoinType: UInt32 {
        if isTestnet { return 1 }
        
        switch self {
        case .bitcoin, .ducatus: return 0
        case .litecoin: return 2
        case .dogecoin: return 3
        case .ethereum, .ethereumPoW, .ethereumFair, .saltPay: return 60
        case .ethereumClassic: return 61
        case .bsc: return 9006
        case .bitcoinCash: return 145
        case .binance: return 714
        case .xrp: return 144
        case .tezos: return 1729
        case .stellar: return 148
        case .cardano: return 1815
        case .rsk: return 137
        case .polygon: return 966
        case .avalanche: return 9000
        case .solana: return 501
        case .fantom: return 1007
        case .polkadot: return 354
        case .kusama: return 434
        case .tron: return 195
        case .arbitrum: return 9001
        case .dash: return 5
        case .gnosis: return 700
        case .optimism: return 614
        case .ton: return 607
        case .kava: return 459
        case .kaspa: return 111111
        case .ravencoin: return 175
        case .cosmos: return 118
        case .terraV1, .terraV2: return 330
        case .cronos: return 10000025
        }
    }
}
