//
//  DynamicCompareMasterKeyTests.swift
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

class DynamicCompareMasterKeyTests: XCTestCase {
    
    // MARK: - Properties

    let addressesUtility = AddressServiceManagerUtility()
    let testVectorsUtility = TestVectorsUtility()
    
}

extension PublicKeyAddressValidatationTests {
    
    func testDynamicCompareMasterKey() {
        do {
            guard let blockchains: [BlockchainSdk.Blockchain] = try testVectorsUtility.getTestVectors(from: DecodableVectors.blockchain.rawValue) else {
                XCTFail("__INVALID_VECTOR__ BLOCKCHAIN DATA IS NIL")
                return
            }
            
            guard let vector: DecodableVectors.MnemonicVector = try testVectorsUtility.getTestVectors(
                from: DecodableVectors.mnemonic.rawValue
            ) else {
                XCTFail("__INVALID_VECTOR__ PUBLIC KEY ADDRESS DATA IS NIL")
                return
            }
            
            blockchains.forEach { blockchain in
                do {
                    let mnemonicServiceUtility = MnemonicServiceManagerUtility(mnemonic: vector.testable.mnemonic)
                    let seed = try mnemonicServiceUtility.getTrustWalletSeed()
                    
                    let trustWalletPrivateKey = try mnemonicServiceUtility.getMasterKeyFromTrustWallet(with: seed, for: blockchain)
                    let tangemSdkPrivateKey = try mnemonicServiceUtility.getMasterKeyFromBIP32(with: seed, for: blockchain)
                    
                    /// Validate private keys
                    XCTAssertEqual(trustWalletPrivateKey.data.hex, tangemSdkPrivateKey.privateKey.hex, "\(blockchain.displayName)!")
                    
                    let trustWalletPublicKey = try mnemonicServiceUtility.getDerivationPublicKeyFromTrustWallet(blockchain: blockchain, derivationPath: nil)
                    let tangemSdkPublicKey = try mnemonicServiceUtility.getDerivationPublicKeyFromTangemSdk(blockchain: blockchain, privateKey: tangemSdkPrivateKey)
                    
                    /// Validate public keys without derivations
                    XCTAssertEqual(trustWalletPublicKey.data.hex, tangemSdkPublicKey.publicKey.hex, "\(blockchain.displayName)!")
                } catch {
                    XCTFail("__INVALID_SEED__ FROM TRUST WALLET \(error)")
                }
            }
            
        } catch let error {
            XCTFail("__INVALID_VECTOR__ \(error)")
            return
        }
    }
    
}
