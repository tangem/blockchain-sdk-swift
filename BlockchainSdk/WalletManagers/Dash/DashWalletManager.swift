//
//  DashWalletManager.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 07.06.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

class DashWalletManager: BitcoinWalletManager {
    override var minimalFee: Decimal { 1.0 }
    override var minimalFeePerByte: Decimal { 1 }
}

extension DashWalletManager: DustRestrictable {
    var dustValue: Amount {
        Amount(with: wallet.blockchain, value: minimalFee)
    }
}
