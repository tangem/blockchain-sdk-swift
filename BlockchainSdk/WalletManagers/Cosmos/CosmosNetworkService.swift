//
//  CosmosNetworkService.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 10.04.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class CosmosNetworkService: MultiNetworkProvider {
    let providers: [CosmosRestProvider]
    var currentProviderIndex: Int = 0
    
    let isTestnet: Bool
        
    init(isTestnet: Bool, providers: [CosmosRestProvider]) {
        self.isTestnet = isTestnet
        self.providers = providers
    }
 
    func accountInfo(for address: String) -> AnyPublisher<Void, Error> {
        .emptyFail
    }
    
    func fee(for transaction: Transaction) -> AnyPublisher<Void, Error> {
        .emptyFail
    }
    
    func send(transaction: Transaction) -> AnyPublisher<Void, Error> {
        .emptyFail
    }
}
