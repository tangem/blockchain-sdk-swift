//
//  AlgorandTransactionParams.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 09.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct AlgorandTransactionParams: TransactionParams {
    let publicKey: Wallet.PublicKey
    let nonce: String
    let round: UInt64
}
