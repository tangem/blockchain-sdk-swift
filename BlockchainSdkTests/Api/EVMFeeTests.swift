//
//  EVMFeeTests.swift
//  BlockchainSdkTests
//
//  Created by Alexander Osokin on 15.06.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

/*
import Foundation
import XCTest
import Combine
import BigInt
@testable import BlockchainSdk


class EVMFeeTests: XCTestCase {
    private var bag = Set<AnyCancellable>()

    func testGasPrice() {
        let expected = expectation(description: "Waiting for response")

        let apiKeys = EthereumApiKeys(
            infuraProjectId: "",
            nowNodesApiKey: "",
            getBlockApiKey: "",
            quickNodeBscCredentials: .init(
                apiKey: "",
                subdomain: "")
        )

        let evmChains = Blockchain.allMainnetCases.filter({ $0.isEvm })
        let items = evmChains
            .map { ($0.displayName,
                    $0.getJsonRpcEndpoints(keys: apiKeys)!.map { EthereumJsonRpcProvider(url: $0, configuration: .init()) }) }

        expected.expectedFulfillmentCount = items.flatMap { $0.1 }.count

        var results = [String]()

        for item in items {
            for provider in item.1 {
                provider
                    .getGasPrice()
                    .sink(receiveCompletion: { compl in
                        switch compl {
                        case .failure(let error):
                            results.append("\(item.0), host: \(provider.host), error: \(error.localizedDescription)")
                            expected.fulfill()
                        case .finished:
                            break
                        }
                    }, receiveValue: { value in
                        guard let res = value.result else {
                            results.append("\(item.0), host: \(provider.host), error. Result is empty")
                            expected.fulfill()
                            return
                        }

                        let weiValue = BigUInt(res.removeHexPrefix(), radix: 16)!
                        let gweiValue = Decimal(Int(weiValue)) / Decimal(1_000_000_000)
                        results.append("\(item.0), host: \(provider.host), gasPrice: \(gweiValue) gwei (\(weiValue) wei)")
                        expected.fulfill()
                    })
                    .store(in: &bag)
            }
        }

        waitForExpectations(timeout: 60)

        results.sort()
        results.forEach {
            print($0)
        }
    }
}
*/
