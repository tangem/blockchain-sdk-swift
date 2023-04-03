//
//  SeedPhraseAddressesCompareTests.swift
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

class SeedPhraseAddressesCompareTests: XCTestCase {
    
    let addressesUtility = AddressServiceManagerUtility()
    
    let mnemonics = [
        "broom ramp luggage this language sketch door allow elbow wife moon impulse",
        "ripple scissors kick mammal hire column oak again sun offer wealth tomorrow wagon turn fatal",
        "history step cheap card humble screen raise seek robot slot coral roof spoil wreck caution",
        "diary shine country alpha bridge coast loan hungry hip media sell crucial swarm share gospel lake visa coin dizzy physical basket",
        "poet spider smile swift roof pilot subject save hand diet ice universe over brown inspire ugly wide economy symbol shove episode patient plug swamp",
        "letter advice cage absurd amount doctor acoustic avoid letter advice cage absurd amount doctor acoustic avoid letter advice cage absurd amount doctor acoustic bless",
        "inmate flip alley wear offer often piece magnet surge toddler submit right radio absent pear floor belt raven price stove replace reduce plate home"
    ]
    
    lazy var wallets = mnemonics.map {
        HDWallet(mnemonic: $0, passphrase: "")!
    }
    
    func testValidateAddressesFromKey() {
        wallets.forEach { wallet in
            addressesUtility.validate(privateKey: wallet.getKeyForCoin(coin: .ethereum), for: .ethereum(testnet: false))
            addressesUtility.validate(privateKey: wallet.getKeyForCoin(coin: .bitcoin), for: .bitcoin(testnet: false))
            addressesUtility.validate(privateKey: wallet.getKeyForCoin(coin: .litecoin), for: .litecoin)
            addressesUtility.validate(privateKey: wallet.getKeyForCoin(coin: .stellar), for: .stellar(testnet: false))
            addressesUtility.validate(privateKey: wallet.getKeyForCoin(coin: .xrp), for: .xrp(curve: .secp256k1))
            addressesUtility.validate(privateKey: wallet.getKeyForCoin(coin: .ton), for: .ton(testnet: false))
            addressesUtility.validate(privateKey: wallet.getKeyForCoin(coin: .ton), for: .ton(testnet: false))
            addressesUtility.validate(privateKey: wallet.getKeyForCoin(coin: .binance), for: .binance(testnet: false))
            addressesUtility.validate(privateKey: wallet.getKeyForCoin(coin: .smartChain), for: .bsc(testnet: false))
            addressesUtility.validate(privateKey: wallet.getKeyForCoin(coin: .solana), for: .solana(testnet: false))
            addressesUtility.validate(privateKey: wallet.getKeyForCoin(coin: .polkadot), for: .polkadot(testnet: false))
            addressesUtility.validate(privateKey: wallet.getKeyForCoin(coin: .kusama), for: .kusama)
            addressesUtility.validate(privateKey: wallet.getKeyForCoin(coin: .tron), for: .tron(testnet: false))
            addressesUtility.validate(privateKey: wallet.getKeyForCoin(coin: .tezos), for: .tezos(curve: .ed25519))
            addressesUtility.validate(privateKey: wallet.getKeyForCoin(coin: .polygon), for: .polygon(testnet: false))
        }
    }
    
    
}
