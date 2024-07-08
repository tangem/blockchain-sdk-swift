//
//  ICPNetworkService.swift
//  BlockchainSdk
//
//  Created by Dmitry Fedorov on 24.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import IcpKit

final class ICPNetworkService: MultiNetworkProvider {
    
    // MARK: - Protperties
    
    let providers: [ICPProvider]
    var currentProviderIndex: Int = 0
    
    private var blockchain: Blockchain
    
    // MARK: - Init
    
    init(providers: [ICPProvider], blockchain: Blockchain) {
        self.providers = providers
        self.blockchain = blockchain
    }
    
    func getBalance(data: Data) -> AnyPublisher<Decimal, Error> {
        providerPublisher { [blockchain] provider in
            provider
                .getInfo(data: data)
                .map { result in
                    result/blockchain.decimalValue
                }
                .eraseToAnyPublisher()
        }
    }
    
    func send(data: Data) -> AnyPublisher<Void, Error> {
        providerPublisher { provider in
            provider
                .send(data: data)
        }
    }
    
    func readState(data: Data, paths: [ICPStateTreePath]) -> AnyPublisher<UInt64?, Error> {
        providerPublisher { provider in
            provider
                .readState(data: data, paths: paths)
                .eraseToAnyPublisher()
        }
    }
}
