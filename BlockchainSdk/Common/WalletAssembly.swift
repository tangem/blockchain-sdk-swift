//
//  BlockchainAssemblyFactory.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 31.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk

typealias AssemblyWallet = WalletManager

struct BlockchainAssemblyInput {
    let blockchain: Blockchain
    let blockchainConfig: BlockchainSdkConfig
    let publicKey: Wallet.PublicKey
    let pairPublicKey: Data?
    let wallet: Wallet
    let networkConfig: NetworkProviderConfiguration
}

enum BlockBookProviderType {
    case NowNodes
    case GetBlock
}

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
