//
//  RadiantTests.swift
//  BlockchainSdkTests
//
//  Created by skibinalexander on 01.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import XCTest
import WalletCore

import BitcoinCore

@testable import BlockchainSdk

final class RadiantTests: XCTestCase {
    private let blockchain = Blockchain.radiant(testnet: false)
}

enum Op: UInt8 {
    case hash160 = 0xA9
    case equal = 0x87
    case dup = 0x76
    case equalVerify = 0x88
    case checkSig = 0xAC
    case pushData1 = 0x4c
    case pushData2 = 0x4d
    case pushData4 = 0x4e
    case op0 = 0x00
    case op1 = 0x51
}
