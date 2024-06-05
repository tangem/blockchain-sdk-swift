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
    
    override func setUp() {
        walletManager.wallet.clearAmounts()
    }

    func testTransactionValidationTest_smoke() {
        walletManager.wallet.addBalance(balance: 100)
        walletManager.wallet.addMana(mana: 100)
        
        XCTAssertNoThrow(
            try walletManager.validate(
                amount: .coinAmount(value: 10),
                fee: .manaFee(value: 0.3)
            )
        )
    }
    
    func testTransactionValidationTest_not_enough_mana() {
        walletManager.wallet.addBalance(balance: 100)
        walletManager.wallet.addMana(mana: 0.2)
        
        do {
            try walletManager.validate(
                amount: .coinAmount(value: 10),
                fee: .manaFee(value: 0.3)
            )
            XCTFail("Expected KoinosWalletManagerError.insufficientMana but no error was thrown")
        } catch let e as KoinosWalletManagerError {
            XCTAssertEqual(e, KoinosWalletManagerError.insufficientMana)
        } catch {
            XCTFail("Unexpected error thrown: \(error)")
        }
    }
    
    func testTransactionValidationTest_amount_exceeds_mana_balance() {
        walletManager.wallet.addBalance(balance: 100)
        walletManager.wallet.addMana(mana: 50)

        do {
            try walletManager.validate(
                amount: .coinAmount(value: 51),
                fee: .manaFee(value: 0.3)
            )
            XCTFail("Expected KoinosWalletManagerError.manaFeeExceedsBalance but no error was thrown")
        } catch let e as KoinosWalletManagerError {
            XCTAssertEqual(e, KoinosWalletManagerError.manaFeeExceedsBalance)
        } catch {
            XCTFail("Unexpected error thrown: \(error)")
        }
    }
    
    func testTransactionValidationTest_coin_balance_does_not_cover_fee() {
        walletManager.wallet.addBalance(balance: 0.2)
        walletManager.wallet.addMana(mana: 0.2)

        do {
            try walletManager.validate(
                amount: .coinAmount(value: 0.2),
                fee: .manaFee(value: 0.3)
            )
            XCTFail("Expected KoinosWalletManagerError.insufficientBalance but no error was thrown")
        } catch let e as KoinosWalletManagerError {
            XCTAssertEqual(e, KoinosWalletManagerError.insufficientBalance)
        } catch {
            XCTFail("Unexpected error thrown: \(error)")
        }
    }
}

private extension Amount {
    static let blockchain = Blockchain.koinos(testnet: false)
    
    static func coinAmount(value: Decimal) -> Amount {
        Amount(
            with: blockchain,
            type: .coin,
            value: value * pow(10, blockchain.decimalCount)
        )
    }
    
    static func manaAmount(value: Decimal) -> Amount {
        Amount(
            type: .feeResource(name: "Mana"),
            currencySymbol: "Mana",
            value: value * pow(10, blockchain.decimalCount),
            decimals: blockchain.decimalCount
        )
    }
}

private extension Fee {
    static func manaFee(value: Decimal) -> Fee {
        Fee(.manaAmount(value: value))
    }
}

private extension Wallet {
    mutating func addBalance(balance: Decimal) {
        add(amount: .coinAmount(value: balance))
    }
    
    mutating func addMana(mana: Decimal) {
        add(
            amount: Amount(
                type: .feeResource(name: "Mana"),
                currencySymbol: "Mana",
                value: mana * pow(10, blockchain.decimalCount),
                decimals: blockchain.decimalCount,
                maxValue: amounts[.coin]?.value
            )
        )
    }
}
