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

struct BlockchainAssemblyFactoryInput {
    let blockchain: Blockchain
    let blockchainConfig: BlockchainSdkConfig
    let publicKey: Wallet.PublicKey
    let pairPublicKey: Data?
    let wallet: Wallet
    let networkConfig: NetworkProviderConfiguration
}

typealias AssemblyWallet = BaseManager & WalletManager

protocol BlockchainAssemblyFactoryProtocol {
    
    /// Access to factory make factory blockchain
    /// - Parameter blockchain: Blockchain enum type
    /// - Returns: Is assembly result
    func canAssembly(blockchain: Blockchain, isTestnet: Bool) -> Bool
    
    /// Blockchain assembly method
    /// - Parameter input: Input data factory
    /// - Returns: Blockchain result
    func assembly(with input: BlockchainAssemblyFactoryInput, isTestnet: Bool) throws -> AssemblyWallet
    
}
