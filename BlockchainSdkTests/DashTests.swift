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
    private let secpDecompressedKey = Data(hexString: "0441DCD64B5F4A039FC339A16300A833A883B218909F2EBCAF3906651C76842C45E3D67E8D2947E6FEE8B62D3D3B6A4D5F212DA23E478DD69A2C6CCC851F300D80")
    private let secpCompressedKey = Data(hexString: "0241DCD64B5F4A039FC339A16300A833A883B218909F2EBCAF3906651C76842C45")
        
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
        let expectedAddress = "Xs92pJsKUXRpbwzxDjBjApiwMK6JysNntG"
        
        // when
        do {
            let address = try addressService.makeAddress(from: secpDecompressedKey)
            
            XCTAssertEqual(address, expectedAddress)
        } catch {
            XCTAssertNil(error)
        }
    }
}
