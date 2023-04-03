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

final class BIP39ServiceManagerUtility {
    
    // MARK: - Properties
    
    private var bip39 = BIP39()
    
    private var mnemonic: String = ""
    private var passphrase: String = ""
    
    private lazy var hdWallet: HDWallet = {
        .init(mnemonic: mnemonic, passphrase: passphrase)!
    }()
    
    private lazy var bip39MnemonicComponents: [String] = {
        (try? bip39.parse(mnemonicString: mnemonic))!
    }()
    
    // MARK: - Implementation
    
    func validate(mnemonic: String, passphrase: String) {
        self.mnemonic = mnemonic
        self.passphrase = passphrase
        
        validate(mnemonic: hdWallet.mnemonic)
        
        do {
            try validateSeed(hdSeed: hdWallet.seed, bip39Seed: bip39.generateSeed(from: bip39MnemonicComponents))
        } catch {
            XCTFail("__INVALID_SEED__ DID NOT CREATED FROM TangemSdk BIP39!")
        }
        
        do {
            try validateMasterKey(hdSeed: hdWallet.seed, bip39Seed: bip39.generateSeed(from: bip39MnemonicComponents))
        } catch {
            XCTFail("__INVALID_SEED__ DID NOT CREATED FROM TangemSdk BIP39!")
        }
    }
    
    // MARK: - Private Implementation
    
    private func validate(mnemonic: String) {
        XCTAssertNotNil(try? bip39.validate(mnemonicComponents: bip39.parse(mnemonicString: mnemonic)))
        XCTAssertTrue(WalletCore.Mnemonic.isValid(mnemonic: mnemonic))
    }
    
    private func validateSeed(hdSeed: Data, bip39Seed: Data) {
        XCTAssertEqual(hdSeed.hexString, bip39Seed.hexString)
    }
    
    private func validateMasterKey(hdSeed: Data, bip39Seed: Data) {
        do {
            let privateKeyHDWallet_ed25519 = hdWallet.getMasterKey(curve: .ed25519).data.hexString
            let privateKeyBIP32_ed25519 = try BIP32().makeMasterKey(from: bip39Seed, curve: .ed25519).privateKey.hexString
            
            let privateKeyHDWallet_secp256k1 = hdWallet.getMasterKey(curve: .secp256k1).data.hexString
            let privateKeyBIP32_secp256k1 = try BIP32().makeMasterKey(from: bip39Seed, curve: .secp256k1).privateKey.hexString
            
            XCTAssertEqual(privateKeyHDWallet_ed25519, privateKeyBIP32_ed25519)
            XCTAssertEqual(privateKeyHDWallet_secp256k1, privateKeyBIP32_secp256k1)
        } catch {
            XCTFail("__INVALID_RPIVATE_KEY__ DID NOT CREATED!")
        }
    }
    
}
