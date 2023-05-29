//
//  WalletAddress.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 29.05.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public struct WalletAddress {
    public let address: Address
    public let publicKey: Wallet.PublicKey
    
    public init(address: Address, publicKey: Wallet.PublicKey) {
        self.address = address
        self.publicKey = publicKey
    }
}
