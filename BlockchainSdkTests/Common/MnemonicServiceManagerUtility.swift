//
//  MnemonicServiceManagerUtility.swift
//  BlockchainSdkTests
//
//  Created by skibinalexander on 03.04.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import XCTest
import CryptoKit
import WalletCore

@testable import BlockchainSdk
@testable import TangemSdk

/// Utility for testing mnemonic & and testing process with generate Extended Keys from mnemonic
final class MnemonicServiceManagerUtility {
    
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
    
    @discardableResult
    /// Basic validation and store local keys wallet
    func getTWDerivationPublicKey(
        blockchain: BlockchainSdk.Blockchain,
        derivationPath: String
    ) throws -> PublicKey {
        do {
            if let coin = CoinType(blockchain) {
                let privateKey = hdWallet.getKey(coin: coin, derivationPath: derivationPath)
                return privateKey.getPublicKey(coinType: coin).compressed
            } else {
                throw NSError(domain: "__INVALID_COIN_TYPE_FOR_KEY__ BLOCKCHAIN \(blockchain.currencySymbol)", code: -1)
            }
        } catch {
            throw NSError(domain: "__INVALID_EXECUTE_KEY__ BLOCKCHAIN \(blockchain.currencySymbol)", code: -1)
        }
    }
    
}

extension MnemonicServiceManagerUtility {
    
    struct ExtendedKey {
        let exPrivateKey: ExtendedPrivateKey
        let exPublicKey: ExtendedPublicKey
    }
    
}
