//
//  ChiaNetworkService.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 14.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class ChiaNetworkService: MultiNetworkProvider {
    
    // MARK: - Protperties
    
    let providers: [ChiaNetworkProvider]
    var currentProviderIndex: Int = 0
    
    private var blockchain: Blockchain
    
    // MARK: - Init
    
    init(providers: [ChiaNetworkProvider], blockchain: Blockchain) {
        self.providers = providers
        self.blockchain = blockchain
    }
    
    // MARK: - Implementation
    
    func getInfo(address: String) -> AnyPublisher<TONWalletInfo, Error> {
        return .emptyFail
    }
    
    func getFee(address: String, message: String) -> AnyPublisher<[Fee], Error> {
        return .emptyFail
    }
    
    func send(message: String) -> AnyPublisher<String, Error> {
        return .emptyFail
    }
    
}
