//
//  DerivationProviderV2.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 24.05.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

public struct DerivationProviderV2: DerivationProvider {
    public func derivations(for blockchain: Blockchain) -> [AddressType : DerivationPath] {
        let coinType = blockchain.bip44CoinType
        
        switch blockchain {
        case .bitcoin, .litecoin:
            return [
                .legacy: BIP44(coinType: coinType).buildPath(),
                .default: BIP44(coinType: coinType).buildPath(),
            ]
        case .stellar, .solana:
            // Path according to sep-0005. https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0005.md
            // Solana path consistent with TrustWallet:
            // https://github.com/trustwallet/wallet-core/blob/456f22d6a8ce8a66ccc73e3b42bcfec5a6afe53a/registry.json#L1013
            return [.default: DerivationPath(nodes: [.hardened(BIP44.purpose),
                                                     .hardened(coinType),
                                                     .hardened(0)])]
        case .cardano(let shelley):
            // We use shelley for all new cards with HD wallets feature
            guard shelley else {
                return [:]
            }
            
            // Path according to CIP-1852. https://cips.cardano.org/cips/cip1852/
            let path = DerivationPath(nodes: [.hardened(1852), // purpose
                                              .hardened(coinType),
                                              .hardened(0),
                                              .nonHardened(0),
                                              .nonHardened(0)])
            return [.legacy: path, .default: path]
        case .bitcoinCash:
            let path = BIP44(coinType: coinType).buildPath()
            return [.legacy: path, .default: path]
        case .ethereum,
                .ethereumPoW,
                .ethereumFair,
                .ethereumClassic,
                .rsk,
                .bsc,
                .polygon,
                .avalanche,
                .fantom,
                .arbitrum,
                .gnosis,
                .optimism,
                .saltPay,
                .kava,
                .cronos:
            let coinType = Blockchain.ethereum(testnet: blockchain.isTestnet).bip44CoinType
            return [.default: BIP44(coinType: coinType).buildPath()]
        case    .binance,
                .xrp,
                .ducatus,
                .tezos,
                .dogecoin,
                .polkadot,
                .kusama,
                .tron,
                .dash,
                .ton,
                .kaspa,
                .ravencoin,
                .cosmos,
                .terraV1,
                .terraV2:
            // Path according to BIP-44. https://github.com/satoshilabs/slips/blob/master/slip-0044.md
            return [.default: BIP44(coinType: coinType).buildPath()]
        }
    }
}
