//
//  BlockchainAnalytics.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 26.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public protocol BlockchainAnalytics {
    func logPolkadotAccountHasBeenResetEvent(value: Bool)
    func logPolkadotAccountHasImmortalTransactions(value: Bool)
}
