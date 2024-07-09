//
//  ICPTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by Dmitry Fedorov on 24.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import WalletCore
import CryptoKit

final class ICPTransactionBuilder {
    // MARK: - Private Properties
    
    private let wallet: Wallet
    
    // MARK: - Init
    
    init(wallet: Wallet) {
        self.wallet = wallet
    }
}
