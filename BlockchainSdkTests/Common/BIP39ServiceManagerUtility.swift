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

final class MnemonicServiceManagerUtility {
    
    // MARK: - Properties
    
    private var mnemonic: String = ""
    private var passphrase: String = ""
    
    private var hdWallet: HDWallet {
        .init(mnemonic: mnemonic, passphrase: passphrase)!
    }
    
    // MARK: - Keys
    
    var privateKey_ed25519: ExtendedPrivateKey!
    var privateKey_secp256k1: ExtendedPrivateKey!
    
    var publicKey_ed25519: ExtendedPublicKey!
    var publicKey_secp256k1: ExtendedPublicKey!
    
    // MARK: - Init
    
    public init(mnemonic: String, passphrase: String = "") {
        self.mnemonic = mnemonic
        self.passphrase = passphrase
    }
    
    // MARK: - Implementation
    
    @discardableResult
    func validate() -> Self {
        validate(mnemonic: hdWallet.mnemonic)
        
        do {
            try validateSeed(hdSeed: hdWallet.seed, bip39Seed: Mnemonic(with: mnemonic).generateSeed(with: passphrase))
            try validateAndStoreKeys(hdSeed: hdWallet.seed, bip39Seed: Mnemonic(with: mnemonic).generateSeed(with: passphrase))
        } catch {
            XCTFail("__INVALID_SEED__ DID NOT CREATED FROM TangemSdk BIP39!")
        }
        
        return self
    }
    
    @discardableResult
    func validate(seed: String, masterKey: String, curve: EllipticCurve) -> Self {
        do {
            let bip39Seed = try Mnemonic(with: mnemonic).generateSeed(with: passphrase)
            try validateSeed(hdSeed: hdWallet.seed, bip39Seed: bip39Seed)
            try validateAndStoreKeys(hdSeed: hdWallet.seed, bip39Seed: Mnemonic(with: mnemonic).generateSeed(with: passphrase))

            switch curve {
            case .secp256k1:
                privateKey_secp256k1 = try BIP32().makeMasterKey(from: bip39Seed, curve: .secp256k1)
                XCTAssertEqual(masterKey, privateKey_secp256k1.privateKey.hexString.lowercased())
            case .ed25519:
                privateKey_ed25519 = try BIP32().makeMasterKey(from: bip39Seed, curve: .ed25519)
                XCTAssertEqual(masterKey, privateKey_ed25519.privateKey.hexString.lowercased())
            default:
                XCTFail("__INVALID_ELIPTIC_CURVE__")
            }
        } catch {
            XCTFail("__INVALID_SEED__")
        }

        return self
    }
    
    @discardableResult
    func validate(
        blockchain: BlockchainSdk.Blockchain,
        executtion: (_ privateKey: ExtendedPrivateKey, _ publicKey: ExtendedPublicKey) -> Void
    ) -> Self {
        guard !privateKey_secp256k1.privateKey.isEmpty || !privateKey_ed25519.privateKey.isEmpty else {
            XCTFail("__INVALID_PRIVATE_KEYS__ RUN -> 'func validate() -> Self'")
            return self
        }
        
        switch blockchain.curve {
        case .secp256k1:
            executtion(privateKey_secp256k1, publicKey_secp256k1)
        case .ed25519:
            executtion(privateKey_ed25519, publicKey_ed25519)
        default:
            XCTFail("__INVALID_ELIPTIC_CURVE__")
        }
        
        return self
    }
    
    // MARK: - Private Implementation
    
    private func validate(mnemonic: String) {
        print("[BIP39ServiceManagerUtility] perform test mnemonic -> \(mnemonic)")
        
        XCTAssertNotNil(try? Mnemonic(with: mnemonic).generateSeed(with: passphrase))
        XCTAssertTrue(WalletCore.Mnemonic.isValid(mnemonic: mnemonic))
    }
    
    private func validateSeed(hdSeed: Data, bip39Seed: Data) throws {
        XCTAssertEqual(hdSeed.hexString, bip39Seed.hexString)
    }
    
    private func validateAndStoreKeys(hdSeed: Data, bip39Seed: Data) {
        do {
            let privateKeyHDWallet_ed25519 = hdWallet.getMasterKey(curve: .ed25519)
            privateKey_ed25519 = try BIP32().makeMasterKey(from: bip39Seed, curve: .ed25519)
            
            let privateKeyHDWallet_secp256k1 = hdWallet.getMasterKey(curve: .secp256k1)
            privateKey_secp256k1 = try BIP32().makeMasterKey(from: bip39Seed, curve: .secp256k1)
            
            XCTAssertEqual(privateKeyHDWallet_ed25519.data.hexString, privateKey_ed25519.privateKey.hexString)
            XCTAssertEqual(privateKeyHDWallet_secp256k1.data.hexString, privateKey_secp256k1.privateKey.hexString)
            
            let publicKeyHDWallet_ed25519 = privateKeyHDWallet_ed25519.getPublicKeyEd25519()
            publicKey_ed25519 = try privateKey_ed25519.makePublicKey(for: .ed25519)
            
            let publicKeyHDWallet_secp256k1 = privateKeyHDWallet_secp256k1.getPublicKeySecp256k1(compressed: true)
            publicKey_secp256k1 = try privateKey_secp256k1.makePublicKey(for: .secp256k1)
            
            XCTAssertEqual(publicKeyHDWallet_ed25519.data.hexString, publicKey_ed25519.publicKey.hexString)
            XCTAssertEqual(publicKeyHDWallet_secp256k1.data.hexString, publicKey_secp256k1.publicKey.hexString)
        } catch {
            XCTFail("__INVALID_MASTER_RPIVATE_KEY__")
        }
    }
    
}
