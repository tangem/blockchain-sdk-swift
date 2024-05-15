//
//  KoinosConstantsTests.swift
//  BlockchainSdkTests
//
//  Created by Aleksei Muraveinik on 15.05.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

@testable import BlockchainSdk
import TangemSdk
import XCTest

final class KoinosConstantsTests: XCTestCase {
    private let decimals = 8
    private let derivation = "m/44'/659'/0'/0/0"
    private let curve = EllipticCurve.secp256k1
    
    private let derivationConfigV1 = DerivationConfigV1()
    private let derivationConfigV2 = DerivationConfigV2()
    private let derivationConfigV3 = DerivationConfigV3()
    
    private let blockchain = Blockchain.koinos(testnet: false)
    private let blockchainTestnet = Blockchain.koinos(testnet: true)
    
    func testCorrectDerivationPathConfigV1() {
        let result = derivationConfigV1.derivationPath(for: blockchain)
        XCTAssertEqual(result, derivation)
    }
    
    func testCorrectDerivationPathConfigV2() {
        let result = derivationConfigV2.derivationPath(for: blockchain)
        XCTAssertEqual(result, derivation)
    }

    func testCorrectDerivationPathConfigV3() {
        let result = derivationConfigV3.derivationPath(for: blockchain)
        XCTAssertEqual(result, derivation)
    }
    
    func testCorrectDerivationPathConfigV1Testnet() {
        let result = derivationConfigV1.derivationPath(for: blockchainTestnet)
        XCTAssertEqual(result, derivation)
    }

    func testCorrectDerivationPathConfigV2Testnet() {
        let result = derivationConfigV2.derivationPath(for: blockchainTestnet)
        XCTAssertEqual(result, derivation)
    }

    func testCorrectDerivationPathConfigV3Testnet() {
        let result = derivationConfigV3.derivationPath(for: blockchainTestnet)
        XCTAssertEqual(result, derivation)
    }
    
    func testCorrectDecimals() {
        XCTAssertEqual(blockchain.decimalCount, decimals)
    }

    func testCorrectDecimalsTestnet() {
        XCTAssertEqual(blockchainTestnet.decimalCount, decimals)
    }
    
    func testCorrectCurve() {
        XCTAssertEqual(blockchain.curve, curve)
    }

    func testCorrectCurveTestnet() {
        XCTAssertEqual(blockchainTestnet.curve, curve)
    }
}
