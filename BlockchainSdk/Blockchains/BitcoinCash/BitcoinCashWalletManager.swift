//
//  BitcoinCashWalletManager.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 14.02.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

class BitcoinCashWalletManager: BitcoinWalletManager {
    override var minimalFeePerByte: Decimal { 1 }
}
