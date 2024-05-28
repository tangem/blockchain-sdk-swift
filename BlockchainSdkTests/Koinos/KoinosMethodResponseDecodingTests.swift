//
//  KoinosMethodResponseDecodingTests.swift
//  BlockchainSdkTests
//
//  Created by Aleksei Muraveinik on 28.05.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import XCTest
@testable import BlockchainSdk

final class KoinosMethodResponseDecodingTests: XCTestCase {
    func testGetAccountNonceResponseDecoding() throws {
        let jsonData = """
        {
            "nonce": "MzI1Mg=="
        }
        """
        .data(using: .utf8)!
        
        let response = try JSONDecoder().decode(KoinosMethod.GetAccountNonce.Response.self, from: jsonData)
        
        XCTAssertEqual(response.nonce, 3252)
    }
}
