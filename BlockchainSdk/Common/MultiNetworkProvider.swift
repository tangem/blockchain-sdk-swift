//
//  MultiNetworkProvider.swift
//  BlockchainSdk
//
//  Created by Andrew Son on 12/03/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class MultiNetworkProvider<T> {
    
    private let providers: [T]
    private var currentProviderIndex = 0
    
    var provider: T {
        providers[currentProviderIndex]
    }
    
    init(providers: [T]) {
        self.providers = providers
    }
    
    func providerSwitchablePublisher<T>(for publisherFactory: @escaping () -> AnyPublisher<T, Error>) -> AnyPublisher<T, Error> {
        publisherFactory()
            .map { [weak self] in
                self?.resetProviders()
                return $0
            }
            .catch { [weak self] error -> AnyPublisher<T, Error> in
                print("Switchable publisher catched error:", error)
                if self?.needRetry() ?? false {
                    print("Switching to next publisher")
                    return self?.providerSwitchablePublisher(for: publisherFactory) ?? .emptyFail
                }
                
                return .anyFail(error: error)
            }
            .eraseToAnyPublisher()
    }
    
    private func needRetry() -> Bool {
        currentProviderIndex += 1
        if currentProviderIndex < providers.count {
            return true
        }
        resetProviders()
        return false
    }
    
    private func resetProviders() {
        currentProviderIndex = 0
    }
}
