//
//  WalletAddress.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 29.05.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

public struct WalletAddress {
    public let address: Address
    public let publicKey: Wallet.PublicKey
        
    public init(address: Address, publicKey: Wallet.PublicKey) {
        self.address = address
        self.publicKey = publicKey
    }
    
    public func xpubKey(isTestnet: Bool) -> String? {
        try? publicKey.derivedKey?.serialize(for: isTestnet ? .testnet : .mainnet)
    }
}
