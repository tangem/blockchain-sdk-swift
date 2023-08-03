//
//  ChiaWalletAssembly.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 10.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct ChiaWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        throw WalletError.empty
    }
}
