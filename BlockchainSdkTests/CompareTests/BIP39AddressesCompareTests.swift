//
//  BIP39CompareTests.swift
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

class BIP39AddressesCompareTests: XCTestCase {
    
    let mnemonics = [
        "broom ramp luggage this language sketch door allow elbow wife moon impulse",
        "ripple scissors kick mammal hire column oak again sun offer wealth tomorrow wagon turn fatal",
        "history step cheap card humble screen raise seek robot slot coral roof spoil wreck caution",
        "diary shine country alpha bridge coast loan hungry hip media sell crucial swarm share gospel lake visa coin dizzy physical basket",
        "poet spider smile swift roof pilot subject save hand diet ice universe over brown inspire ugly wide economy symbol shove episode patient plug swamp",
        "letter advice cage absurd amount doctor acoustic avoid letter advice cage absurd amount doctor acoustic avoid letter advice cage absurd amount doctor acoustic bless",
        "inmate flip alley wear offer often piece magnet surge toddler submit right radio absent pear floor belt raven price stove replace reduce plate home"
    ]
    
    // MARK: - Properties
    
    let bip39Utility = BIP39ServiceManagerUtility()
    
    // MARK: - Implementation
    
    func testValidateMnemonics() {
        mnemonics.forEach {
            bip39Utility.validate(mnemonic: $0, passphrase: "")
        }
    }
    
}

