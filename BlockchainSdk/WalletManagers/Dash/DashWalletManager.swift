//
//  DashWalletManager.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 07.06.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

class DashWalletManager: BitcoinWalletManager {}

extension DashWalletManager: DustRestrictable {
    var dustValue: Amount {
        Amount(with: wallet.blockchain, value: minimalFee)
    }
}
