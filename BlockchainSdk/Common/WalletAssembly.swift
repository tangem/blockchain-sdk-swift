//
//  BlockchainAssemblyFactory.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 31.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

typealias AssemblyWallet = WalletManager

/// Input data for assembly wallet manager
struct BlockchainAssemblyInput {
    let blockchain: Blockchain
    let blockchainConfig: BlockchainSdkConfig
    let pairPublicKey: Data?
    let wallet: Wallet
    let networkConfig: NetworkProviderConfiguration
}

/// Main assembly wallet manager interface
protocol WalletAssemblyProtocol {
    
    /// Assembly to access any providers
    static var providerAssembly: ProviderAssembly { get }
    
    // MARK: - Wallet Assembly
    
    /// Blockchain assembly method
    /// - Parameter input: Input data factory
    /// - Returns: Blockchain result
    static func make(with input: BlockchainAssemblyInput) throws -> AssemblyWallet
    
}

extension WalletAssemblyProtocol {
    
    static var providerAssembly: ProviderAssembly {
        return ProviderAssembly()
    }
    
}
