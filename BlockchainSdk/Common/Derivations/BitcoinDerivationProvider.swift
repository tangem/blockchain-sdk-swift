//
//  BitcoinDerivationProvider.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 24.05.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

public struct BitcoinDerivationProvider: DerivationProvider {
    private let style: DerivationStyle
    
    public init(style: DerivationStyle) {
        self.style = style
    }
    
    public func derivations(for blockchain: Blockchain) -> [AddressType: DerivationPath] {
        let coinType = blockchain.bip44CoinType
        let bip44 = BIP44(coinType: coinType, account: 0, change: .external, addressIndex: 0).buildPath()
        
        switch style {
        case .legacy, .new, .v1, .v2:
            return [.legacy: bip44, .default: bip44]
        case .v3:
            // SegWit path according to BIP-84.
            // https://github.com/bitcoin/bips/blob/master/bip-0084.mediawiki
            let bip84 = DerivationPath(nodes: [.hardened(84), // purpose
                                               .hardened(coinType),
                                               .hardened(0),
                                               .nonHardened(0),
                                               .nonHardened(0)])
            return [.legacy: bip44, .default: bip84]
        }
    }
}
