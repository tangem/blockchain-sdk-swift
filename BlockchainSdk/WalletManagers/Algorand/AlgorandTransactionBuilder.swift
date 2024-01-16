//
//  AlgorandTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 09.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import WalletCore
import BigInt

final class AlgorandTransactionBuilder {
    private let isTestnet: Bool
    private var coinType: CoinType { .algorand }
    
    init(isTestnet: Bool) {
        self.isTestnet = isTestnet
    }
}
