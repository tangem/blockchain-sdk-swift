//
//  MultiNetworkProvider.swift
//  BlockchainSdk
//
//  Created by Andrew Son on 12/03/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Moya

@available(iOS 13.0, *)
protocol MultiNetworkProvider: AnyObject, HostProvider {
    associatedtype Provider: HostProvider
    
    var providers: [Provider] { get }
    var currentProviderIndex: Int { get set }
}

extension MultiNetworkProvider {
    var provider: Provider {
        providers[currentProviderIndex]
    }
    
    var host: String { provider.host }
    
    func providerPublisher<T>(for requestPublisher: @escaping (_ provider: Provider) -> AnyPublisher<T, Error>) -> AnyPublisher<T, Error> {
        requestPublisher(provider)
            .catch { [weak self] error -> AnyPublisher<T, Error> in
                if let moyaError = error as? MoyaError, case let .statusCode(resp) = moyaError {
                    print("Switchable publisher catched error: \(moyaError). Response message: \(String(describing: String(data: resp.data, encoding: .utf8)))")
                }
                
                if case WalletError.noAccount = error {
                    return .anyFail(error: error)
                }
                
                print("Switchable publisher catched error:", error)
                if self?.needRetry() ?? false {
                    print("Switching to next publisher")
                    return self?.providerPublisher(for: requestPublisher) ?? .emptyFail
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

protocol HostProvider {
    var host: String { get }
}
