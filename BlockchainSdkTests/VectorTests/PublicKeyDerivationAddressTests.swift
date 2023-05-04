//
//  PublicKeyDerivationAddressTests.swift
//  BlockchainSdkTests
//
//  Created by skibinalexander on 25.04.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import XCTest
import CryptoKit
import TangemSdk
import WalletCore

@testable import BlockchainSdk

class PublicKeyDerivationAddressTests: XCTestCase {
    let addressesUtility = AddressServiceManagerUtility()
    let testVectorsUtility = TestVectorsUtility()
}

/*
 - 0. Compare derivation from vector file with BlockchainSdk.derivationPath(.new)
 - 1. Obtain MASTER Trustwallet Keys and keys from TrangemSdk and compare keys
 - 2. Obtain PUBLIC Trustwallet Keys and keys from TrangemSdk and compare keys
 - 2. Obtain ADDRESSES TeustWallet service and BlockchainSdk service for derivation public keys
 - 4. Compare addresses from services
 */

extension PublicKeyDerivationAddressTests {
    
    func testPublicKeyDerivationAddressVector() {
        do {
            guard let blockchains: [BlockchainSdk.Blockchain] = try testVectorsUtility.getTestVectors(from: DecodableVectors.blockchain.rawValue) else {
                XCTFail("__INVALID_VECTOR__ BLOCKCHAIN DATA IS NIL")
                return
            }
            
            guard let vector: DecodableVectors.CompareVector = try testVectorsUtility.getTestVectors(from: DecodableVectors.trustWalletCompare.rawValue) else {
                XCTFail("__INVALID_VECTOR__ COMPARE DATA IS NIL")
                return
            }
            
            try vector.testable.forEach { test in
                guard let blockchain = blockchains.first(where: { $0.codingKey == test.blockchain }) else {
                    print("__INVALID_VECTOR__ MATCH BLOCKCHAIN KEY IS NIL \(test.blockchain)")
                    return
                }
                
                guard CoinType(blockchain) != nil else { return }
                
                //FIXME: - Remove when all test will be is completed
                guard !(test.skip ?? false) else { return }
                
                // MARK: -  Step - 0

                XCTAssertEqual(test.derivation, blockchain.derivationPath(for: .new)!.rawPath, "-> \(blockchain.displayName)")
                
                // MARK: -  Step - 1 / 2
                
                let keysServiceUtility = KeysServiceManagerUtility(mnemonic: vector.mnemonic.words)
                let seed = try keysServiceUtility.getTrustWalletSeed()

                let trustWalletPrivateKey = try keysServiceUtility.getMasterKeyFromTrustWallet(for: blockchain)
                let tangemSdkPrivateKey = try keysServiceUtility.getMasterKeyFromBIP32(with: seed, for: blockchain)

                // Validate private keys
                XCTAssertEqual(trustWalletPrivateKey.data.hex, tangemSdkPrivateKey.privateKey.hex, "\(blockchain.displayName)")

                let trustWalletPublicKey = try keysServiceUtility.getPublicKeyFromTrustWallet(blockchain: blockchain, privateKey: trustWalletPrivateKey)
                let tangemSdkPublicKey = try keysServiceUtility.getPublicKeyFromTangemSdk(blockchain: blockchain, privateKey: tangemSdkPrivateKey)

                // Compare public keys without derivations
                XCTAssertEqual(trustWalletPublicKey.data.hex, tangemSdkPublicKey.publicKey.hex, "\(blockchain.displayName)")

                // MARK: - Step 3

                let trustWalletDerivationPublicKey = try keysServiceUtility.getPublicKeyFromTrustWallet(
                    blockchain: blockchain,
                    derivation: test.derivation
                )

                // MARK: - Step 4

                // Need for skip test derivation address from undefined public key
                guard let tangemWalletPublicKey = test.walletPublicKey else {
                    return
                }

                do {
                    let trustWalletAddress = try addressesUtility.makeTrustWalletAddress(
                        publicKey: trustWalletDerivationPublicKey.uncompressed.data,
                        for: blockchain
                    )

                    let tangemWalletAddress = try addressesUtility.makeTangemAddress(
                        publicKey: Data(hex: tangemWalletPublicKey),
                        for: blockchain,
                        addressType: .init(rawValue: test.addressType ?? "")
                    )

                    // Compare addresses
                    XCTAssertEqual(trustWalletAddress, tangemWalletAddress, "\(blockchain.displayName)!")
                } catch {
                    XCTFail("__INVALID_VECTOR__ \(error) -> \(blockchain.displayName)")
                    return
                }
            }
            
        } catch let error {
            XCTFail("__INVALID_VECTOR__ \(error)")
            return
        }
    }
    
}
