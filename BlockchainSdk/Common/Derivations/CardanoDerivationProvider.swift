//
//  CardanoDerivationProvider.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 24.05.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

public struct CardanoDerivationProvider: DerivationProvider {
    private let shelley: Bool
    
    public init(shelley: Bool) {
        self.shelley = shelley
    }
    
    public func derivations(for blockchain: Blockchain) -> [AddressType: DerivationPath] {
        // We use shelley for all new cards with HD wallets feature
        guard shelley else {
            return [:]
        }
        
        let coinType = blockchain.bip44CoinType
        
        // Path according to CIP-1852. https://cips.cardano.org/cips/cip1852/
        return [.default:  DerivationPath(nodes: [.hardened(1852), // purpose
                                                  .hardened(coinType),
                                                  .hardened(0),
                                                  .nonHardened(0),
                                                  .nonHardened(0)])]
    }
}
