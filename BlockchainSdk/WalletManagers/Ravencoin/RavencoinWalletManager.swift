//
//  RavencoinWalletManager.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 14.10.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

class RavencoinWalletManager: BitcoinWalletManager {
    override var minimalFeePerByte: Decimal { 0.00001 }
}
