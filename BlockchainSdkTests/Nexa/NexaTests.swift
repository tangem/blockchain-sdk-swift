//
//  NexaTests.swift
//  BlockchainSdkTests
//
//  Created by Sergey Balashov on 22.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import XCTest

@testable import BlockchainSdk

final class NexaTests: XCTestCase {
    func testAddressBuilder() throws {
        // Given
        let service = NexaAddressService()
        let publicKey = Data(hex: "02050a5a0e8dd69a531e51c4feb2c89d7fa7de66b57e427fb1699a382d221fd79d")
        
        // When
        let address = try service.makeAddress(from: publicKey).value
        
        // Then
        let expected = "nexa:nqtsq5g5krcetfc0csvszztt8wdhf5yxydzfw0e65fe452ft"
        XCTAssertEqual(address, expected)
    }
    
    func testAddressValidation() throws {
        // Given
        let service = NexaAddressService()

        XCTAssertTrue(service.validate("nexa:nqtsq5g5krcetfc0csvszztt8wdhf5yxydzfw0e65fe452ft"))
        XCTAssertFalse(service.validate("nexa:xqtsq5g5krcetfc0csvszztt8wdhf5yxydzfw0e65fe452ft"))
    }
}
