//
//  BlockchainAssemblyFactory.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 31.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

/// Input data for assembly wallet manager
struct WalletManagerAssemblyInput {
    let blockchain: Blockchain
    let blockchainConfig: BlockchainSdkConfig
    let pairPublicKey: Data?
    let wallet: Wallet
    let networkConfig: NetworkProviderConfiguration
}

/// Main assembly wallet manager interface
protocol WalletManagerAssembly {
    
    /// Assembly to access any providers
    var providerAssembly: NetworkProviderAssembly { get }
    
    // MARK: - Wallet Assembly
    
    /// Blockchain assembly method
    /// - Parameter input: Input data factory
    /// - Returns: Blockchain result
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager
    
}

extension WalletManagerAssembly {
    
    var providerAssembly: NetworkProviderAssembly {
        return NetworkProviderAssembly()
    }
    
}
