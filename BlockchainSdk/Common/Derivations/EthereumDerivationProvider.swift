//
//  EthereumDerivationProvider.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 24.05.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

public struct EthereumDerivationProvider: DerivationProvider {
    private let style: DerivationStyle
    
    public init(style: DerivationStyle) {
        self.style = style
    }
    
    public func derivations(for blockchain: Blockchain) -> [AddressType: DerivationPath] {
        let coinType: UInt32
        
        switch style {
        case .legacy, .v1:
            coinType = blockchain.bip44CoinType
        case .new, .v2, .v3:
            coinType = Blockchain.ethereum(testnet: blockchain.isTestnet).bip44CoinType
        }

        let bip44 = BIP44(coinType: coinType, account: 0, change: .external, addressIndex: 0).buildPath()
        
        return [.default: bip44]
    }
}
