//
//  RadiantNetworkProvider.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 12.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class RadiantNetworkProvider: MultiNetworkProvider {
    let providers: [RadiantElectrumWebSocketProvider]
    var currentProviderIndex: Int = 0
    
    private let decimalValue: Decimal
    
    init(providers: [RadiantElectrumWebSocketProvider], decimalValue: Decimal) {
        self.providers = providers
        self.decimalValue = decimalValue
    }
    
    func getBalance(address: String) -> AnyPublisher<Decimal, Error> {
        providerPublisher { provider in
                .init {
                    do {
                        let balance = try await provider.getBalance(address: address)
                        return Decimal(balance.confirmed) / self.decimalValue
                    } catch {
                        print(error)
                        throw error
                    }
                }
        }
    }
}
