//
//  ChiaTests.swift
//  BlockchainSdkTests
//
//  Created by skibinalexander on 10.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import XCTest
import CryptoKit
import TangemSdk

@testable import BlockchainSdk

class ChiaTests: XCTestCase {
    
    func testConditionSpend() {
        let address = "txch14gxuvfmw2xdxqnws5agt3ma483wktd2lrzwvpj3f6jvdgkmf5gtq8g3aw3"
        let amount: UInt64 = 235834596465
        let encodedAmount = amount.chiaEncode()

        let solution1 = try! "ffffff33ffa0" +
            ChiaConstant.getPuzzleHash(address: address).hex + "ff8" + String(encodedAmount.count) +
            Data(encodedAmount).hex + "808080"
        
        let condition = try! CreateCoinCondition(
            destinationPuzzleHash: ChiaConstant.getPuzzleHash(address: address),
            amount: amount
        ).toProgram()
        
        let solution2 = try! ClvmProgram.from(list: [ClvmProgram.from(list: [condition])]).serialize().hex

        let equal = solution1.lowercased() == solution2.lowercased()
    }
    
}
