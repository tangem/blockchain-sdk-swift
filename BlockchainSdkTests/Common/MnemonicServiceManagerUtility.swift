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
    func validate(
        blockchain: BlockchainSdk.Blockchain,
        _ execution: (_ privateKey: ExtendedPrivateKey, _ publicKey: ExtendedPublicKey) -> Void
    ) -> Self {
        do {
            let keys = try validateAndStoreMasterKeys(
                hdSeed: hdWallet.seed,
                bip39Seed: Mnemonic(with: mnemonic).generateSeed(with: passphrase)
            )
            
            guard let secp256k1 = keys?.0, let ed25519 = keys?.1 else {
                XCTFail("__INVALID_PRIVATE_KEYS__ RUN -> 'func validate() -> Self'")
                return self
            }
            
            guard !secp256k1.exPrivateKey.privateKey.isEmpty || !ed25519.exPrivateKey.privateKey.isEmpty else {
                XCTFail("__INVALID_PRIVATE_KEYS__ RUN -> 'func validate() -> Self'")
                return self
            }
            
            switch blockchain.curve {
            case .secp256k1:
                execution(secp256k1.exPrivateKey, secp256k1.exPublicKey)
            case .ed25519:
                execution(ed25519.exPrivateKey, ed25519.exPublicKey)
            default:
                XCTFail("__INVALID_ELIPTIC_CURVE__")
            }
            
        } catch {
            XCTFail("__INVALID_SEED__ DID NOT CREATED FROM TangemSdk BIP39!")
        }
        
        return self
    }
    
    @discardableResult
    /// Basic validation and store local keys wallet
    func validate(
        blockchain: BlockchainSdk.Blockchain,
        derivation: CompareDerivation?,
        sdkPublicKey: Data? = nil,
        _ execution: (_ publicKey: PublicKey) -> Void
    ) -> Self {
        if let derivation = derivation {
            // Compare validate derivation from local and reference
            XCTAssertEqual(derivation.local, derivation.reference)
            
            let privateKey = try! hdWallet.getKey(coin: .init(blockchain), derivationPath: derivation.reference)
            let publicKey = try! privateKey.getPublicKeyByType(pubkeyType: .init(blockchain))
            
            if let sdkPublicKey = sdkPublicKey {
                let sdkPublicKey = try! PublicKey(data: sdkPublicKey, type: .init(blockchain))!
                
                // Compare validate hash public keys from TrustWallet and TangemSdk
                
                XCTAssertEqual(publicKey.data.hexString, sdkPublicKey.data.hexString)
                
                // Return keypair of derivation path
                execution(sdkPublicKey)
            } else {
                // Return keypair of derivation path
                execution(publicKey)
            }
        } else {
            let privateKey = try! hdWallet.getKeyForCoin(coin: .init(blockchain))
            let publicKey = try! privateKey.getPublicKey(coinType: .init(blockchain))
            
            if let sdkPublicKey = sdkPublicKey {
                let sdkPublicKey = try! PublicKey(data: sdkPublicKey, type: .init(blockchain))!
                
                // Compare validate hash public keys from TrustWallet and TangemSdk
                XCTAssertEqual(publicKey.data.hexString, sdkPublicKey.data.hexString)
                
                // Return keypair of derivation path
                execution(sdkPublicKey)
            } else {
                // Return keypair of derivation path
                execution(publicKey)
            }
        }
        
        return self
    }
    
    // MARK: - Private Implementation
    
    /// Perform generate private and public keys and store keys to local properties for next use
    /// - Parameters:
    ///   - hdSeed: Seed from TrustWallet
    ///   - bip39Seed: Seed from TangemSdk
    private func validateAndStoreMasterKeys(hdSeed: Data, bip39Seed: Data) throws -> (ExtendedKey, ExtendedKey)? {
        do {
            let privateKeyHDWallet_ed25519 = hdWallet.getMasterKey(curve: .ed25519)
            let privateKey_ed25519 = try BIP32().makeMasterKey(from: bip39Seed, curve: .ed25519)
            
            let privateKeyHDWallet_secp256k1 = hdWallet.getMasterKey(curve: .secp256k1)
            let privateKey_secp256k1 = try BIP32().makeMasterKey(from: bip39Seed, curve: .secp256k1)
            
            // Verify private keys from TrustWallet & TangemSdk
            XCTAssertEqual(privateKeyHDWallet_ed25519.data.hexString, privateKey_ed25519.privateKey.hexString)
            XCTAssertEqual(privateKeyHDWallet_secp256k1.data.hexString, privateKey_secp256k1.privateKey.hexString)
            
            let publicKeyHDWallet_ed25519 = privateKeyHDWallet_ed25519.getPublicKeyEd25519()
            let publicKey_ed25519 = try privateKey_ed25519.makePublicKey(for: .ed25519)
            
            let publicKeyHDWallet_secp256k1 = privateKeyHDWallet_secp256k1.getPublicKeySecp256k1(compressed: true)
            let publicKey_secp256k1 = try privateKey_secp256k1.makePublicKey(for: .secp256k1)
            
            // Verify public keys from TrustWallet & TangemSdk
            XCTAssertEqual(publicKeyHDWallet_ed25519.data.hexString, publicKey_ed25519.publicKey.hexString)
            XCTAssertEqual(publicKeyHDWallet_secp256k1.data.hexString, publicKey_secp256k1.publicKey.hexString)
            
            return (
                .init(exPrivateKey: privateKey_secp256k1, exPublicKey: publicKey_secp256k1),
                .init(exPrivateKey: privateKey_ed25519, exPublicKey: publicKey_ed25519)
            )
        } catch {
            XCTFail("__INVALID_GEN_KEYS__")
            return nil
        }
    }
    
    /// Perform generate private and public keys and store keys to local properties for next use
    /// - Parameters:
    ///   - hdSeed: Seed from TrustWallet
    ///   - bip39Seed: Seed from TangemSdk
    private func validateAndStoreDerivationKeys(hdSeed: Data, bip39Seed: Data, derivationPath: String) {
        
    }
    
}

extension MnemonicServiceManagerUtility {
    
    struct ExtendedKey {
        let exPrivateKey: ExtendedPrivateKey
        let exPublicKey: ExtendedPublicKey
    }
    
    struct CompareDerivation {
        let local: String
        let reference: String
    }
    
}
