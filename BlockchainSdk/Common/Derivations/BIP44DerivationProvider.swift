//
//  BIP44DerivationProvider.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 24.05.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

public struct BIP44DerivationProvider: DerivationProvider {
    public func derivations(for blockchain: Blockchain) -> [AddressType: DerivationPath] {
        let coinType = blockchain.bip44CoinType
        let bip44 = BIP44(coinType: coinType, account: 0, change: .external, addressIndex: 0).buildPath()
        
        return [.default: bip44]
    }
}
