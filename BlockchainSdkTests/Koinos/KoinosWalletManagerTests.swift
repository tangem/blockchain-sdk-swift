//
//  KoinosWalletManagerTests.swift
//  BlockchainSdkTests
//
//  Created by Aleksei Muraveinik on 04.06.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import XCTest
@testable import BlockchainSdk

final class KoinosWalletManagerTests: XCTestCase {
    private let walletManager = KoinosWalletManager(
        wallet: Wallet(
            blockchain: .koinos(testnet: false),
            addresses: [
                .default: PlainAddress(
                    value: "1AYz8RCnoafLnifMjJbgNb2aeW5CbZj8Tp",
                    publicKey: .init(seedKey: .init(), derivationType: nil),
                    type: .default
                )
            ]
        ),
        networkService: KoinosNetworkService(
            providers: [],
            decimalCount: 8
        ), 
        transactionBuilder: KoinosTransactionBuilder(isTestnet: false)
    )

    func testTransactionValidationTest_smoke() {
        walletManager.wallet.setBalance(balance: 100)
        walletManager.wallet.setMana(mana: 100)
        
        XCTAssertNoThrow(
            try walletManager.validate(
                amount: .coinAmount(value: 10),
                fee: .manaAmount(value: 0.3)
            )
        )
    }
    
    func testTransactionValidationTest_not_enough_mana() {
        walletManager.wallet.setBalance(balance: 100)
        walletManager.wallet.setMana(mana: 0.2)
        
        XCTAssertThrowsError(
            try walletManager.validate(
                amount: .coinAmount(value: 10),
                fee: .manaAmount(value: 0.3)
            )
        )
    }
    
    func testTransactionValidationTest_amount_exceeds_mana_balance() {
        walletManager.wallet.setBalance(balance: 100)
        walletManager.wallet.setMana(mana: 50)

        XCTAssertThrowsError(
            try walletManager.validate(
                amount: .coinAmount(value: 51),
                fee: .manaAmount(value: 0.3)
            )
        )
    }
    
    func testTransactionValidationTest_coin_balance_does_not_cover_fee() {
        walletManager.wallet.setBalance(balance: 0.2)
        walletManager.wallet.setMana(mana: 0.2)

        XCTAssertThrowsError(
            try walletManager.validate(
                amount: .coinAmount(value: 0.2),
                fee: .manaAmount(value: 0.3)
            )
        )
    }
}

private extension Wallet {
    mutating func setBalance(balance: Decimal) {
        clearAmounts()
        add(amount: .coinAmount(value: balance))
    }
    
    mutating func setMana(mana: Decimal) {
        clearAmounts()
        add(amount: .manaAmount(value: mana))
    }
}

private extension Amount {
    static let blockchain = Blockchain.koinos(testnet: false)
    
    static func coinAmount(value: Decimal) -> Amount {
        Amount(
            with: blockchain,
            value: value * pow(10, blockchain.decimalCount)
        )
    }
    
    static func manaAmount(value: Decimal) -> Amount {
        Amount(
            with: blockchain,
            type: .reserve, // TODO: [KOINOS] AmountType.FeeResource()
            value: value * pow(10, blockchain.decimalCount)
        )
    }
}

private extension Fee {
    static func manaAmount(value: Decimal) -> Fee {
        Fee(.manaAmount(value: value))
    }
}
