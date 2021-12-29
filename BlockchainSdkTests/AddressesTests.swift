//
//  AddressesTests.swift
//  BlockchainSdkTests
//
//  Created by Alexander Osokin on 29.12.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import XCTest
import TangemSdk

class AddressesTests: XCTestCase {
    private let secpPrivKey = Data(hexString: "83686EF30173D2A05FD7E2C8CB30941534376013B903A2122CF4FF3E8668355A")
    private let secpDecompressedKey = Data(hexString: "0441DCD64B5F4A039FC339A16300A833A883B218909F2EBCAF3906651C76842C45E3D67E8D2947E6FEE8B62D3D3B6A4D5F212DA23E478DD69A2C6CCC851F300D80")
    private let secpCompressedKey = Data(hexString: "0241DCD64B5F4A039FC339A16300A833A883B218909F2EBCAF3906651C76842C45")
    private let edKey = Data(hex: "9FE5BB2CC7D83C1DA10845AFD8A34B141FD8FD72500B95B1547E12B9BB8AAC3D")
  
    func testBtc() {
        let btc = Blockchain.bitcoin(testnet: false)
        let addr_dec = btc.makeAddresses(from: secpDecompressedKey, with: nil)
        let addr_comp = btc.makeAddresses(from: secpCompressedKey, with: nil)
        
//        let addr3 = btc.makeAddresses(from: edKey, with: nil)
//        XCTAssertEqual(addr3.count, 0) //todo: uncomment after cryptoutils refactoring
        
        XCTAssertEqual(addr_dec.count, 2)
        XCTAssertEqual(addr_comp.count, 2)
        
        let bech32_dec = addr_dec.first(where: { $0.type == .bitcoin(type: .bech32)})!
        let bech32_comp = addr_comp.first(where: { $0.type == .bitcoin(type: .bech32)})!
        XCTAssertEqual(bech32_dec.value, bech32_comp.value)
        XCTAssertEqual(bech32_dec.value, "bc1qc2zwqqucrqvvtyxfn78ajm8w2sgyjf5edc40am")
        XCTAssertEqual(bech32_dec.localizedName, bech32_comp.localizedName)
        
        let leg_dec = addr_dec.first(where: { $0.type == .bitcoin(type: .legacy) })!
        let leg_comp = addr_comp.first(where: { $0.type == .bitcoin(type: .legacy) })!
        XCTAssertEqual(leg_dec.localizedName, leg_comp.localizedName)
        XCTAssertEqual(leg_dec.value, "1HTBz4DRWpDET1QNMqsWKJ39WyWcwPWexK")
        XCTAssertEqual(leg_comp.value, "1JjXGY5KEcbT35uAo6P9A7DebBn4DXnjdQ")
    }
    
    func testBtcTestnet() {
        let btc = Blockchain.bitcoin(testnet: true)
        let addr_dec = btc.makeAddresses(from: secpDecompressedKey, with: nil)
        let addr_comp = btc.makeAddresses(from: secpCompressedKey, with: nil)
        
//        let addr3 = btc.makeAddresses(from: edKey, with: nil)
//        XCTAssertEqual(addr3.count, 0) //todo: uncomment after cryptoutils refactoring
        
        XCTAssertEqual(addr_dec.count, 2)
        XCTAssertEqual(addr_comp.count, 2)
        
        let bech32_dec = addr_dec.first(where: { $0.type == .bitcoin(type: .bech32)})!
        let bech32_comp = addr_comp.first(where: { $0.type == .bitcoin(type: .bech32)})!
        XCTAssertEqual(bech32_dec.value, bech32_comp.value)
        XCTAssertEqual(bech32_dec.localizedName, bech32_comp.localizedName)
        XCTAssertEqual(bech32_dec.value, "tb1qc2zwqqucrqvvtyxfn78ajm8w2sgyjf5e87wuxg")
        
        let leg_dec = addr_dec.first(where: { $0.type == .bitcoin(type: .legacy) })!
        let leg_comp = addr_comp.first(where: { $0.type == .bitcoin(type: .legacy) })!
        XCTAssertEqual(leg_dec.localizedName, leg_comp.localizedName)
        XCTAssertEqual(leg_dec.value, "mwy9H7JQKqeVE7sz5Qqt9DFUNy7KtX7wHj")
        XCTAssertEqual(leg_comp.value, "myFUZbAJ3e2hpCNnWfMWz2RyTBNm7vdnSQ")
    }
}
