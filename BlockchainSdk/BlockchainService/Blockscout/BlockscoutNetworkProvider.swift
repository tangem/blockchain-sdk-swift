//
//  BlockscoutNetworkProvider.swift
//  BlockchainSdk
//
//  Created by Andrew Son on 10/02/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class BlockscoutNetworkProvider {
    private let networkProvider: NetworkProvider<BlockscoutTarget>
    
    init(configuration: NetworkProviderConfiguration) {
        self.networkProvider = NetworkProvider(configuration: configuration)
    }
    
    func loadTransactionHistory(for address: String) -> AnyPublisher<[BlockscoutTransaction], Error> {
        return networkProvider.requestPublisher(.transactionHistory(address: address))
            .filterSuccessfulStatusAndRedirectCodes()
            .map(BlockscoutResponse<[BlockscoutTransaction]>.self)
            .mapError { $0 as Error }
            .map { $0.result }
            .eraseToAnyPublisher()
    }
}
