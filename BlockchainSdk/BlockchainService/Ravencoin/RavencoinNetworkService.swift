//
//  RavencoinNetworkService.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 16.10.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine

class RavencoinNetworkService: BitcoinNetworkProvider {
    var supportsTransactionPush: Bool { true }
    var host: String { RavencoinTarget.addressInfo("").baseURL.absoluteString }
    
    private let provider = NetworkProvider<RavencoinTarget>()
    
    func getInfo(address: String) -> AnyPublisher<BitcoinResponse, Error> {
        .emptyFail
    }
    
    func getFee() -> AnyPublisher<BitcoinFee, Error> {
        .emptyFail
    }
    
    func send(transaction: String) -> AnyPublisher<String, Error> {
        .emptyFail
    }
    
    func push(transaction: String) -> AnyPublisher<String, Error> {
        .emptyFail
    }
    
    func getSignatureCount(address: String) -> AnyPublisher<Int, Error> {
        .emptyFail
    }
}
