//
//  DashTests.swift
//  BlockchainSdkTests
//
//  Created by Sergey Balashov on 09.06.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import XCTest
import BitcoinCore

@testable import BlockchainSdk

class DashTests: XCTestCase {
    private let secpPrivKey = Data(hexString: "83686EF30173D2A05FD7E2C8CB30941534376013B903A2122CF4FF3E8668355A")
        
    override class func setUp() {
        super.setUp()
    }
    
    override class func tearDown() {
        super.tearDown()
    }
    
    func testCreateAddressMainnet() {
        // given
        let blockchain = Blockchain.dash(testnet: false)
        let addressService = blockchain.getAddressService()
        let expectedAddress = "XeByhGmrY64164TQYvk3HKFD96gtqzYmHu"
        
        // when
        do {
            let address = try addressService.makeAddress(from: secpPrivKey)
            XCTAssertEqual(address, expectedAddress)
        } catch {
            XCTAssertNil(error)
        }
    }
    
    func testCreateAddressTestnet() {}
}
