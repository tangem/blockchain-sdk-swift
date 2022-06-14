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
import Combine

@testable import BlockchainSdk

class DashTests: XCTestCase {
    private let secpPrivKey = Data(hexString: "83686EF30173D2A05FD7E2C8CB30941534376013B903A2122CF4FF3E8668355A")
    private let secpDecompressedKey = Data(hexString: "0441DCD64B5F4A039FC339A16300A833A883B218909F2EBCAF3906651C76842C45E3D67E8D2947E6FEE8B62D3D3B6A4D5F212DA23E478DD69A2C6CCC851F300D80")
    private let secpCompressedKey = Data(hexString: "0241DCD64B5F4A039FC339A16300A833A883B218909F2EBCAF3906651C76842C45")
    
    private var bag: Set<AnyCancellable> = []
    
    // MARK: - Create addresses

    func testCreateAddressCompressedMainnet() {
        // given
        let blockchain = Blockchain.dash(testnet: false)
        let addressService = blockchain.getAddressService()
        let expectedAddress = "XtRN6njDCKp3C2VkeyhN1duSRXMkHPGLgH"
        
        // when
        do {
            let address = try addressService.makeAddress(from: secpCompressedKey)
            
            XCTAssertEqual(address, expectedAddress)
        } catch {
            XCTAssertNil(error)
        }
    }
    
    func testCreateAddressDecompressedMainnet() {
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
    
    func testCreateAddressTestnet() {
        // given
        let blockchain = Blockchain.dash(testnet: true)
        let addressService = blockchain.getAddressService()
        let expectedAddress = "yMfdoASh4QEM3zVpZqgXJ8St38X7VWnzp7"
        let compressedKey = Data(
            hexString: "021DCF0C1E183089515DF8C86DACE6DA08DC8E1232EA694388E49C3C66EB79A418"
        )
        
        // when
        do {
            let address = try addressService.makeAddress(from: compressedKey)
            
            XCTAssertEqual(address, expectedAddress)
        } catch {
            XCTAssertNil(error)
        }
    }
    
    // MARK: - Network
    
    func testDashCryptoAPIsNetworkProviderGetInfo() {
        let network = CryptoAPIsNetworkProvider(coinType: .dash, apiKey: "5991c724d463d8c887660a527809ada3317beb81")
        
        let expectation = expectation(description: "getInfo")
    
        network.getInfo(address: "yMfdoASh4QEM3zVpZqgXJ8St38X7VWnzp7")
            .sink(receiveCompletion: { completion in
                switch completion {
                case let .failure(error):
                    XCTFail(error.localizedDescription)
                case .finished:
                    expectation.fulfill()
                }
            }, receiveValue: { _ in })
            .store(in: &bag)
        
        waitForExpectations(timeout: 10)
    }
}
