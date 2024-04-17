//
//  BlockchainNetworkId.swift
//  BlockchainSdk
//
//  Created by Andrew Son on 10/04/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public enum BlockchainNetworkId: String {
    case bitcoin
    case litecoin
    case stellar
    case ethereum
    case ethereumPoW = "ethereum-pow-iou"
    case disChain = "ethereumfair" // keep existing id for compatibility
    case ethereumClassic = "ethereum-classic"
    case rsk = "rootstock"
    case bitcoinCash = "bitcoin-cash"
    case binance = "binancecoin"
    case cardano
    case xrp = "xrp"
    case ducatus
    case tezos
    case dogecoin
    case bsc = "binance-smart-chain"
    case polygon = "polygon-pos"
    case avalanche
    case solana
    case fantom
    case polkadot
    case kusama
    case azero = "aleph-zero"
    case tron
    case arbitrum = "arbitrum-one"
    case dash
    case gnosis = "xdai"
    case optimism = "optimistic-ethereum"
    case ton = "the-open-network"
    case kava
    case kaspa
    case ravencoin
    case cosmos
    case terraV1 = "terra"
    case terraV2 = "terra-2"
    case cronos
    case telos
    case octa = "octaspace"
    case chia
    case near = "near-protocol"
    case decimal
    case veChain = "vechain"
    case xdc = "xdc-network"
    case algorand
    case shibarium = "shibarium"
    case aptos
    case hedera = "hedera-hashgraph"
    case areon = "areon-network"
    case playa3ullGames = "playa3ull-games"
    case pulsechain
    case aurora
    case manta = "manta-network"
    case zkSync = "zksync"
    case moonbeam
    case polygonZkEVM = "polygon-zkevm"
    case moonriver
    case mantle
    case flare = "flare-network"
    case taraxa
    case radiant
    case base

    init(for blockchain: Blockchain) {
        switch blockchain {
        case .bitcoin: self = .bitcoin
        case .litecoin: self = .litecoin
        case .stellar: self = .stellar
        case .ethereum: self = .ethereum
        case .ethereumPoW: self = .ethereumPoW
        case .disChain: self = .disChain
        case .ethereumClassic: self = .ethereumClassic
        case .rsk: self = .rsk
        case .bitcoinCash: self = .bitcoinCash
        case .binance: self = .binance
        case .cardano: self = .cardano
        case .xrp: self = .xrp
        case .ducatus: self = .ducatus
        case .tezos: self = .tezos
        case .dogecoin: self = .dogecoin
        case .bsc: self = .bsc
        case .polygon: self = .polygon
        case .avalanche: self = .avalanche
        case .solana: self = .solana
        case .fantom: self = .fantom
        case .polkadot: self = .polkadot
        case .kusama: self = .kusama
        case .azero: self = .azero
        case .tron: self = .tron
        case .arbitrum: self = .arbitrum
        case .dash: self = .dash
        case .gnosis: self = .gnosis
        case .optimism: self = .optimism
        case .ton: self = .ton
        case .kava: self = .kava
        case .kaspa: self = .kaspa
        case .ravencoin: self = .ravencoin
        case .cosmos: self = .cosmos
        case .terraV1: self = .terraV1
        case .terraV2: self = .terraV2
        case .cronos: self = .cronos
        case .telos: self = .telos
        case .octa: self = .octa
        case .chia: self = .chia
        case .near: self = .near
        case .decimal: self = .decimal
        case .veChain: self = .veChain
        case .xdc: self = .xdc
        case .algorand: self = .algorand
        case .shibarium: self = .shibarium
        case .aptos: self = .aptos
        case .hedera: self = .hedera
        case .areon: self = .areon
        case .playa3ullGames: self = .playa3ullGames
        case .pulsechain: self = .pulsechain
        case .aurora: self = .aurora
        case .manta: self = .manta
        case .zkSync: self = .zkSync
        case .moonbeam: self = .moonbeam
        case .polygonZkEVM: self = .polygonZkEVM
        case .moonriver: self = .moonriver
        case .mantle: self = .mantle
        case .flare: self = .flare
        case .taraxa: self = .taraxa
        case .radiant: self = .radiant
        case .base: self = .base
        }
    }
}
