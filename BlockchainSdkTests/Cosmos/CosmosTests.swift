//
//  CosmosTests.swift
//  BlockchainSdkTests
//
//  Created by Andrey Chukavin on 10.04.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import XCTest

@testable import BlockchainSdk

class CosmosTests: XCTestCase {
    func testDecodingNetworkModels() {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        let accountResponse = #"{"account":{"@type":"/cosmos.auth.v1beta1.BaseAccount","address":"cosmos15cmkwr223aymmjtvgvpuv37vr83zeua2sxqtat","pub_key":{"@type":"/cosmos.crypto.secp256k1.PubKey","key":"Awjv+yiteafCIp2X0C2QLoJCFTg8K7voJGfQxeRw6tNo"},"account_number":"725072","sequence":"2"}}"#
        XCTAssertNoThrow(try decoder.decode(CosmosAccountResponse.self, from: accountResponse.data(using: .utf8)!))
        
        let balanceResponse = #"{"balances":[{"denom":"uatom","amount":"3998996"}],"pagination":{"next_key":null,"total":"1"}}"#
        XCTAssertNoThrow(try decoder.decode(CosmosBalanceResponse.self, from: balanceResponse.data(using: .utf8)!))
    }
}
