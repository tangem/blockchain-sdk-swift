//
//  BIP39ServiceManagerUtility.swift
//  BlockchainSdkTests
//
//  Created by skibinalexander on 03.04.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import XCTest
import CryptoKit
import TangemSdk
import WalletCore

@testable import BlockchainSdk

final class KeysServiceManagerUtility {
    
    // MARK: - Properties
    
    private var mnemonic: String = ""
    private var passphrase: String = ""
    
    private var hdWallet: HDWallet {
        .init(mnemonic: mnemonic, passphrase: passphrase)!
    }
    
    // MARK: - Init
    
    public init(mnemonic: String, passphrase: String = "") {
        self.mnemonic = mnemonic
        self.passphrase = passphrase
    }
    
    // MARK: - Implementation
    
    func getTrustWalletSeed() throws -> Data {
        try Mnemonic(with: mnemonic).generateSeed(with: passphrase)
    }
    
    func getMasterKeyFromTrustWallet(for blockchain: BlockchainSdk.Blockchain) throws -> PrivateKey {
        try hdWallet.getMasterKey(curve: .init(blockchain.curve))
    }
    
    func getMasterKeyFromBIP32(with seed: Data, for blockchain: BlockchainSdk.Blockchain) throws -> ExtendedPrivateKey {
        try BIP32().makeMasterKey(from: seed, curve: blockchain.curve)
    }

    /// Basic validation and store local keys wallet
    func getPublicKeyFromTrustWallet(
        blockchain: BlockchainSdk.Blockchain,
        privateKey: PrivateKey
    ) throws -> PublicKey {
        return try privateKey.getPublicKeyByType(pubkeyType: .init(blockchain)).compressed
    }
    
    /// Basic validation and store local keys wallet
    func getPublicKeyFromTangemSdk(
        blockchain: BlockchainSdk.Blockchain,
        privateKey: ExtendedPrivateKey
    ) throws -> ExtendedPublicKey {
        do {
            return try privateKey.makePublicKey(for: blockchain.curve)
        } catch {
            throw NSError(domain: "__INVALID_EXECUTE_KEY__ BLOCKCHAIN \(blockchain.currencySymbol)", code: -1)
        }
    }
    
    // MARK: - asjkdaksldlk
    
    /// Basic validation and store local keys wallet
    func getPublicKeyFromTrustWallet(
        blockchain: BlockchainSdk.Blockchain,
        derivation: String
    ) throws -> PublicKey {
        if let coin = CoinType(blockchain) {
            return try hdWallet.getKey(coin: coin, derivationPath: derivation).getPublicKeyByType(pubkeyType: .init(blockchain))
        } else {
            throw NSError(domain: "__INVALID_EXECUTE_KEY__ BLOCKCHAIN \(blockchain.currencySymbol)", code: -1)
        }
    }
    
}
