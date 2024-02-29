//
//  TelosWalletManager.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 09.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

class TelosWalletManager: EthereumWalletManager {
    override var allowsFeeSelection: Bool { false }
}
