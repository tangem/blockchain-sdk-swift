//
//  TONWalletINfo.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 02.02.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public struct TONWalletInfo {
    
    /// Wallet balance
    let balance: Decimal
    
    /// Sequence number last transaction
    let seqno: Int
    
    /// Wallet availability
    let isAvailable: Bool
    
}
