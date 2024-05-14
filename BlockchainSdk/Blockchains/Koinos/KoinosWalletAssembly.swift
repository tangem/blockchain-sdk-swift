//
//  KoinosWalletAssembly.swift
//  BlockchainSdk
//
//  Created by Aleksei Muraveinik on 06.05.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import TangemSdk

// TODO: [KOINOS] Implement KoinosWalletAssembly
// https://tangem.atlassian.net/browse/IOS-6758
struct KoinosWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        throw BlockchainSdkError.notImplemented
    }
}
