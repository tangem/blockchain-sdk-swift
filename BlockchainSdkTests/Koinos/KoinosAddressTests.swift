//
//  KoinosTests.swift
//  BlockchainSdkTests
//
//  Created by Aleksei Muraveinik on 14.05.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import BitcoinCore
@testable import BlockchainSdk
import XCTest

final class KoinosAddressTests: XCTestCase {
    private let addressService = KoinosAddressService(networkParams: BitcoinNetwork.mainnet.networkParams)

    func testMakeAddress() {
        let publicKey = "03B2D98CF41E82D9B99842A1D05860A1B06532015138F9067239706E06EE38E621"
        let expectedAddress = "1AYz8RCnoafLnifMjJbgNb2aeW5CbZj8Tp"

        XCTAssertEqual(try! addressService.makeAddress(from: publicKey.data(using: .hexadecimal)!).value, expectedAddress)
    }
    
    func testValidateCorrectAddress() {
        let address = "1AYz8RCnoafLnifMjJbgNb2aeW5CbZj8Tp"

        XCTAssertTrue(addressService.validate(address))
    }

    func testValidateIncorrectAddress() {
        let address = "1AYz8RCnoafLnifMjJbgNb2aeW5CbZj8T"

        XCTAssertFalse(addressService.validate(address))
    }
}
