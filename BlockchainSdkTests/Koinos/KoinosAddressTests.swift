//
//  KoinosTests.swift
//  BlockchainSdkTests
//
//  Created by Aleksei Muraveinik on 14.05.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import BitcoinCore
import XCTest
@testable import BlockchainSdk

final class KoinosAddressTests: XCTestCase {
    private let addressService = KoinosAddressService(networkParams: BitcoinNetwork.mainnet.networkParams)

    func testMakeAddress() throws {
        let publicKey = Data(hex: "03B2D98CF41E82D9B99842A1D05860A1B06532015138F9067239706E06EE38E621")
        let expectedAddress = "1AYz8RCnoafLnifMjJbgNb2aeW5CbZj8Tp"

        XCTAssertEqual(try addressService.makeAddress(from: publicKey).value, expectedAddress)
    }
    
    func testValidateCorrectAddress() {
        let address = "1AYz8RCnoafLnifMjJbgNb2aeW5CbZj8Tp"

        XCTAssertTrue(addressService.validate(address))
    }

    func testValidateIncorrectAddress() {
        let address = "1AYz8RCnoafLnifMjJbgNb2aeW5CbZj8T"

        XCTAssertFalse(addressService.validate(address))
    }
    
    func testEdError() {
        let edKey = Data(hex: "9FE5BB2CC7D83C1DA10845AFD8A34B141FD8FD72500B95B1547E12B9BB8AAC3D")
        
        XCTAssertThrowsError(try addressService.makeAddress(from: edKey))
    }
}
