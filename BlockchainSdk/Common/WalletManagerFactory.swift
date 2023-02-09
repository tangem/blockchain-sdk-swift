//
//  WalletManagerFactory.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 06.12.2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import stellarsdk
import BitcoinCore
import Solana_Swift

@available(iOS 13.0, *)
public class WalletManagerFactory {
    
    private let config: BlockchainSdkConfig
    
    // MARK: - Init
    
    public init(config: BlockchainSdkConfig) {
        self.config = config
    }
    
    /// Base wallet manager initializer
    /// - Parameters:
    ///   - blockchain: blockhain to create. If nil, card native blockchain will be used
    ///   - seedKey: Public key  of the wallet
    ///   - derivedKey: Derived ExtendedPublicKey by the card
    ///   - derivation: DerivationParams
    /// - Returns: WalletManager?
    public func makeWalletManager(blockchain: Blockchain,
                                  seedKey: Data,
                                  derivedKey: ExtendedPublicKey,
                                  derivation: DerivationParams) throws -> WalletManager {
        
        var derivationPath: DerivationPath? = nil
        
        switch derivation {
        case .default(let derivationStyle):
            derivationPath = blockchain.derivationPath(for: derivationStyle)
        case .custom(let path):
            derivationPath = path
        }
        
        return try makeWalletManager(from: blockchain,
                                     publicKey: .init(seedKey: seedKey,
                                                      derivedKey: derivedKey,
                                                      derivationPath: derivationPath))
    }
    
    /// Legacy wallet manager initializer
    /// - Parameters:
    ///   - blockchain: blockhain to create. If nil, card native blockchain will be used
    ///   - walletPublicKey: Wallet's publicKey
    /// - Returns: WalletManager
    public func makeWalletManager(blockchain: Blockchain, walletPublicKey: Data) throws -> WalletManager {
        try makeWalletManager(from: blockchain,
                              publicKey: .init(seedKey: walletPublicKey, derivedKey: nil, derivationPath: nil))
    }
    
    /// Wallet manager initializer for twin cards
    /// - Parameters:
    ///   - blockchain: blockhain to create. If nil, card native blockchain will be used
    ///   - walletPublicKey: Wallet's publicKey
    public func makeTwinWalletManager(walletPublicKey: Data, pairKey: Data, isTestnet: Bool) throws -> WalletManager {
        try makeWalletManager(from: .bitcoin(testnet: isTestnet),
                              publicKey: .init(seedKey: walletPublicKey, derivedKey: nil, derivationPath: nil),
                              pairPublicKey: pairKey)
    }
    
    // MARK: - Private Implementation
    
    /// Private implementation facroty creation wallet manager
    /// - Parameters:
    ///   - blockchain: Type of blockchain
    ///   - publicKey: Public key wallet
    ///   - pairPublicKey: Optional data pair public key
    /// - Returns: WalletManager model
    private func makeWalletManager(from blockchain: Blockchain,
                           publicKey: Wallet.PublicKey,
                           pairPublicKey: Data? = nil) throws -> WalletManager {
        
        return try blockchain.assembly.make(
            with: .init(
                blockchain: blockchain,
                blockchainConfig: config,
                publicKey: publicKey,
                pairPublicKey: pairPublicKey,
                wallet: Wallet(
                    blockchain: blockchain,
                    addresses: blockchain.makeAddresses(from: publicKey.blockchainKey, with: pairPublicKey),
                    publicKey: publicKey
                ),
                networkConfig: config.networkProviderConfiguration(for: blockchain)
            )
        )
    }
}

extension WalletManagerFactory {
    public enum DerivationParams {
        case `default`(DerivationStyle)
        case custom(DerivationPath)
    }
}
