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
    
    func validate(mnemonic: String, targetSeed: Data) {
        XCTFail("__INVALID_ADDRESS__ BLOCKCHAIN FROM PUBLIC KEY!")
    }
    
}
