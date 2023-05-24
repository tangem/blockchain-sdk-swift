//
//  SEP0005DerivationProvider.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 24.05.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

public struct SEP0005DerivationProvider: DerivationProvider {
    public func derivations(for blockchain: Blockchain) -> [AddressType: DerivationPath] {
        let coinType = blockchain.bip44CoinType
        
        // Path according to sep-0005. https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0005.md
        // Solana path consistent with TrustWallet:
        // https://github.com/trustwallet/wallet-core/blob/456f22d6a8ce8a66ccc73e3b42bcfec5a6afe53a/registry.json#L1013
        return [.default: DerivationPath(nodes: [.hardened(BIP44.purpose),
                                                 .hardened(coinType),
                                                 .hardened(0)])]
    }
}
