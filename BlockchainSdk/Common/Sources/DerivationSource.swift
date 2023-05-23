//
//  DerivationSource.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 23.05.2023.
//

import Foundation
import TangemSdk

public struct DerivationSource {
    public func derivations(for blockchain: Blockchain, style: DerivationStyle) -> [AddressType: DerivationPath] {
        guard blockchain.curve == .secp256k1 || blockchain.curve == .ed25519 else {
            return [:]
        }
        
        let coinType = coinType(for: blockchain, style: style)
        let bip44 = BIP44(coinType: coinType, account: 0, change: .external, addressIndex: 0).buildPath()
        
        switch blockchain {
        case .stellar, .solana:
            // Path according to sep-0005. https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0005.md
            // Solana path consistent with TrustWallet:
            // https://github.com/trustwallet/wallet-core/blob/456f22d6a8ce8a66ccc73e3b42bcfec5a6afe53a/registry.json#L1013
            return [.default: DerivationPath(nodes: [.hardened(BIP44.purpose),
                                                     .hardened(coinType),
                                                     .hardened(0)])]
        case .cardano(let shelley):
            // We use shelley for all new cards with HD wallets feature
            if !shelley {
                return [:]
            }
            
            // Path according to CIP-1852. https://cips.cardano.org/cips/cip1852/
            return [.default:  DerivationPath(nodes: [.hardened(1852), // purpose
                                                      .hardened(coinType),
                                                      .hardened(0),
                                                      .nonHardened(0),
                                                      .nonHardened(0)])]
        case .bitcoin, .litecoin:
            guard style == .v2 else { fallthrough }
            
            // SegWit path according to BIP-84.
            // https://github.com/bitcoin/bips/blob/master/bip-0084.mediawiki
            let bip84 = DerivationPath(nodes: [.hardened(84), // purpose
                                               .hardened(coinType),
                                               .hardened(0),
                                               .nonHardened(0),
                                               .nonHardened(0)])
            
            return [.legacy: bip44, .default: bip84]
        default:
            return [.default: bip44]
        }
    }
    
    public func coinType(for blockchain: Blockchain, style: DerivationStyle) -> UInt32 {
        if blockchain.isTestnet {
            return 1
        }
        
        switch style {
        case .new, .v2:
            guard blockchain.isEvm else { fallthrough }
            
            // Ethereum coinType
            return 60
            
        case .legacy, .v1, .v3:
            return blockchain.bip44CoinType
        }
    }
}

private extension Blockchain {
    /// Source: https://github.com/satoshilabs/slips/blob/master/slip-0044.md
    var bip44CoinType: UInt32 {
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
