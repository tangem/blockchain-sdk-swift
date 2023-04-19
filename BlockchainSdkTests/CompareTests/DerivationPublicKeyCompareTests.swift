//
//  DerivationPublicKeyCompareTests.swift
//  BlockchainSdkTests
//
//  Created by skibinalexander on 19.04.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import XCTest
import CryptoKit
import TangemSdk
import WalletCore

@testable import BlockchainSdk

class DerivationPublicKeyCompareTests: XCTestCase {
    
    // MARK: - Properties
    
    let blockchainUtility = BlockchainServiceManagerUtility()
    let addressUtility = AddressServiceManagerUtility()
    
    lazy var mnemonicUtility = {
        MnemonicServiceManagerUtility(mnemonic: blockchainUtility.mnemonics[0])
    }()
    
    // MARK: - Implementation
    
    func testPublicKeyCompare() {
        blockchainUtility.blockchains.forEach { blockchain in
            if CoinType(blockchain) != nil {
                guard let twReference = blockchainUtility.twDerivations.first(where: { $0.blockchain == blockchain }) else {
                    XCTFail("__INVALID_TW_DERIVATION__ BLOCKCHAIN \(blockchain.displayName)!")
                    return
                }
                
                guard let sdkPublicKey = blockchainUtility.sdkPublicKeysFromMnemonic.first(where: { $0.blockchain == blockchain }) else {
                    XCTFail("__INVALID_SDK_PUBLIC_KEY__ BLOCKCHAIN \(blockchain.displayName)!")
                    return
                }
                
                do {
                    let twPublicKey = try mnemonicUtility.getTWDerivationPublicKey(blockchain: blockchain, derivationPath: twReference.path)
                    XCTAssertEqual(twPublicKey.data.hex.uppercased(), sdkPublicKey.key, "\(blockchain.displayName)")
                } catch {
                    XCTFail("__INVALID_TW_PUBLIC_KEY__ BLOCKCHAIN \(blockchain.currencySymbol)!")
                }
            }
        }
    }
    
}
