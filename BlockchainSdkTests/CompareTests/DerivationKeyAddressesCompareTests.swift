//
//  DerivationKeyAddressesCompareTests.swift
//  BlockchainSdkTests
//
//  Created by skibinalexander on 13.04.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import XCTest
import CryptoKit
import TangemSdk
import WalletCore

@testable import BlockchainSdk

class DerivationKeyAddressesCompareTests: XCTestCase {
    
    // MARK: - Properties
    
    let blockchainUtility = BlockchainServiceManagerUtility()
    let addressUtility = AddressServiceManagerUtility()
    
    lazy var mnemonicUtility = {
        MnemonicServiceManagerUtility(mnemonic: blockchainUtility.mnemonics[0])
    }()
    
    // MARK: - Implementation
    
    func testAddressesCompare() {
        blockchainUtility.blockchains.forEach { blockchain in
            if CoinType(blockchain) != nil {
                guard let sdkPublicKey = blockchainUtility.sdkPublicKeysFromMnemonic.first(where: { $0.blockchain == blockchain }) else {
                    XCTFail("__INVALID_SDK_PUBLIC_KEY__ BLOCKCHAIN \(blockchain.displayName)!")
                    return
                }
                
                guard let twAddress = blockchainUtility.twAddressesMnemonicWithDerivation.first(where: { $0.blockchain == blockchain }) else {
                    XCTFail("__INVALID_TW_ADDRESS__ BLOCKCHAIN \(blockchain.displayName)!")
                    return
                }
                
                addressUtility.validate(address: twAddress.address, publicKey: Data(hex: sdkPublicKey.key), for: blockchain)
            }
        }
    }
    
}

// Тест вектор (сид фраза, кривая, деривация с ТВ наша деривация из метода)
// Сравнить мастер ключ в тв и сдк мастер ключи одинаковые
// Сравниваем деривации
// Провалидировать адрес
// Инструкцию
