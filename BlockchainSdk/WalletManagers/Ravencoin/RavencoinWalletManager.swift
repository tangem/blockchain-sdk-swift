//
//  RavencoinWalletManager.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 14.10.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

class RavencoinWalletManager: BitcoinWalletManager {
    /// These are the current default values in the ravencore library involved on these checks:
    /// Transaction.FEE_PER_KB: 10000 (satoshis per kilobyte) = 0.0001 RVN per Kilobyte
    /// https://github.com/raven-community/ravencore-lib/blob/master/docs/transaction.md
    override var minimalFeePerByte: Decimal { 0.0001 / 1024 }
}
