//
//  DerivationConfigV3.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 24.05.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

/// Documentation:
/// Types:
/// - `Stellar`, `Solana`, `TON`. According to `SEP0005`
/// https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0005.md
/// - `Polkadot`, `Kusama` used to all nodes in the path is hardened
/// https://wiki.polkadot.network/docs/learn-account-advanced#derivation-paths
/// - `Cardano`. According to  `CIP1852`
/// https://cips.cardano.org/cips/cip1852/
/// - `Bitcoin`, `Litecoin`. Default address is `SegWit`. According to `BIP-84`
/// https://github.com/bitcoin/bips/blob/master/bip-0084.mediawiki
/// - `EVM-like` without `Ethereum classic` with `Ethereum` coinType(60).
/// - `All else`. According to `BIP44`
/// https://github.com/satoshilabs/slips/blob/master/slip-0044.md
public struct DerivationConfigV3: DerivationConfig {
    public func derivations(for blockchain: Blockchain) -> [AddressType: String] {
        switch blockchain {
        case .bitcoin:
            return [.default: "m/84'/0'/0'/0/0"]
        case .litecoin:
            return [.default: "m/84'/2'/0'/0/0"]
        case .stellar:
            return [.default: "m/44'/148'/0'"]
        case .solana:
            return [.default: "m/44'/501'/0'"]
        case .cardano:
            return [.default: "m/44'/1815'/0'/0/0"]
        case .bitcoinCash:
            return [.legacy: "m/44'/145'/0'/0/0", .default: "m/44'/145'/0'/0/0"]
        case .ethereum,
                .ethereumPoW,
                .ethereumFair,
                .saltPay,
                .rsk,
                .bsc,
                .polygon,
                .avalanche,
                .fantom,
                .arbitrum,
                .gnosis,
                .optimism,
                .kava,
                .cronos,
                .telos:
            return [.default: "m/44'/60'/0'/0/0"]
        case .ethereumClassic:
            return [.default: "m/44'/61'/0'/0/0"]
        case .binance:
            return [.default: "m/44'/714'/0'/0/0"]
        case .xrp:
            return [.default: "m/44'/144'/0'/0/0"]
        case .ducatus:
            return [.default: "m/44'/0'/0'/0/0"]
        case .tezos:
            return [.default: "m/44'/1729'/0'/0/0"]
        case .dogecoin:
            return [.default: "m/44'/3'/0'/0/0"]
        case .polkadot:
            return [.default: "m/44'/354'/0'/0'/0'"]
        case .kusama:
            return [.default: "m/44'/434'/0'/0'/0'"]
        case .azero:
            return [.default: "m/44'/643'/0'/0'/0'"]
        case .tron:
            return [.default: "m/44'/195'/0'/0/0"]
        case .dash:
            return [.default: "m/44'/5'/0'/0/0"]
        case .ton:
            return [.default: "m/44'/607'/0'"]
        case .kaspa:
            return [.default: "m/44'/111111'/0'/0/0"]
        case .ravencoin:
            return [.default: "m/44'/175'/0'/0/0"]
        case .cosmos:
            return [.default: "m/44'/118'/0'/0/0"]
        case .terraV1, .terraV2:
            return [.default: "m/44'/330'/0'/0/0"]
        case .octa:
            return [.default: "m/44'/60'/0'/0/0"]
        }
    }
}
