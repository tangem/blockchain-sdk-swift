//
//  CryptoAPIsNetworkProviderTests.swift
//  BlockchainSdkTests
//
//  Created by Sergey Balashov on 16.06.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import XCTest
import Combine

@testable import BlockchainSdk

class CryptoAPIsNetworkProviderTests: XCTestCase {
    private let apiKey = "5991c724d463d8c887660a527809ada3317beb81"
    private var bag: Set<AnyCancellable> = []
    
    func testDashCryptoAPIsNetworkProviderGetInfo() {
        let network = CryptoAPIsNetworkProvider(coinType: .dash, apiKey: apiKey)
        
        let expectation = expectation(description: "getInfo")
        
        network.getInfo(address: "yMfdoASh4QEM3zVpZqgXJ8St38X7VWnzp7")
            .sink(receiveCompletion: { completion in
                switch completion {
                case let .failure(error):
                    XCTFail(error.localizedDescription)
                case .finished:
                    expectation.fulfill()
                }
            }, receiveValue: { response in
                print(response)
            })
            .store(in: &bag)
        
        waitForExpectations(timeout: 10)
    }
    
    func testDashCryptoAPIsNetworkProviderSendTx() {
        let hex = "01000000018e2ce1ecb4f36075ec43d6280c4ee327340d277d36672c961fd0d5cbf0a8f744000000006b483045022100fd7ff4da521c2cc018ba560b6eb0a97139e459a273b9e5fec089999134071023022041bae0be56ec30a4a62ea02113c0b7d6eb1042b8fd6e1808efc2988b0cdf55600121021dcf0c1e183089515df8c86dace6da08dc8e1232ea694388e49c3c66eb79a418000000000200e1f505000000001976a9141ec5c66e9789c655ae068d35088b4073345fe0b088ace66b6b00000000001976a9140ec99567a126d0e6b9f4d207d89d1494a198b50488ac00000000"
        
        let network = CryptoAPIsNetworkProvider(coinType: .dash, apiKey: apiKey)
        
        let expectation = expectation(description: "send(transaction:)")
        
        network.send(transaction: hex)
            .sink(receiveCompletion: { completion in
                switch completion {
                case let .failure(error):
                    XCTFail(error.localizedDescription)
                case .finished:
                    expectation.fulfill()
                }
            }, receiveValue: { response in
                print(response)
            })
            .store(in: &bag)
        
        waitForExpectations(timeout: 10)
    }
}
