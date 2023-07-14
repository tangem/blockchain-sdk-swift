//
//  Blockchain+AllCases.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 24.05.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

extension Blockchain {
    /// Temporary solution unlit we removed `testnet` flag from a `case` blockchain
    static var allMainnetCases: [Blockchain] {
        // Did you get a compilation error here? If so, add your new blockchain to the array below
        switch Blockchain.bitcoin(testnet: false) {
        case .bitcoin: break
        case .litecoin: break
        case .stellar: break
        case .ethereum: break
        case .ethereumClassic: break
        case .rsk: break
        case .bitcoinCash: break
        case .binance: break
        case .cardano: break
        case .xrp: break
        case .ducatus: break
        case .tezos: break
        case .dogecoin: break
        case .bsc: break
        case .polygon: break
        case .avalanche: break
        case .solana: break
        case .fantom: break
        case .polkadot: break
        case .kusama: break
        case .azero: break
        case .tron: break
        case .arbitrum: break
        case .dash: break
        case .gnosis: break
        case .optimism: break
        case .ethereumFair: break
        case .ethereumPoW: break
        case .saltPay: break
        case .ton: break
        case .kava: break
        case .kaspa: break
        case .ravencoin: break
        case .cosmos: break
        case .terraV1: break
        case .terraV2: break
        case .cronos: break
        case .telos: break
            // READ BELOW:
            //
            // Did you get a compilation error here? If so, add your new blockchain to the array below
        }
        
        return [
            .ethereum(testnet: false),
            .ethereumClassic(testnet: false),
            .litecoin,
            .bitcoin(testnet: false),
            .bitcoinCash(testnet: false),
            .xrp(curve: .secp256k1),
            .rsk,
            .binance(testnet: false),
            .tezos(curve: .secp256k1),
            .stellar(testnet: false),
            .cardano,
            .ducatus,
            .dogecoin,
            .bsc(testnet: false),
            .polygon(testnet: false),
            .avalanche(testnet: false),
            .solana(testnet: false),
            .polkadot(testnet: false),
            .kusama,
            .azero(testnet: false),
            .fantom(testnet: false),
            .tron(testnet: false),
            .arbitrum(testnet: false),
            .dash(testnet: false),
            .gnosis,
            .optimism(testnet: false),
            .ethereumFair,
            .ethereumPoW(testnet: false),
            .saltPay,
            .ton(testnet: false),
            .kava(testnet: false),
            .kaspa,
            .ravencoin(testnet: false),
            .cosmos(testnet: false),
            .terraV1,
            .terraV2,
            .cronos,
        ]
    }
}
