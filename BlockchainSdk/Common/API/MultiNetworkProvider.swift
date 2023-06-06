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
import TangemSdk

@available(iOS 13.0, *)
protocol MultiNetworkProvider: AnyObject, HostProvider {
    associatedtype Provider: HostProvider
    
    var providers: [Provider] { get }
    var currentProviderIndex: Int { get set }
    var exceptionHandler: ExternalExceptionHandler? { get }
}

extension MultiNetworkProvider {
    var provider: Provider {
        providers[currentProviderIndex]
    }
    
    var host: String { provider.host }
    
    func providerPublisher<T>(for requestPublisher: @escaping (_ provider: Provider) -> AnyPublisher<T, Error>) -> AnyPublisher<T, Error> {
        let currentHost = provider.host
        return requestPublisher(provider)
            .catch { [weak self] error -> AnyPublisher<T, Error> in
                guard let self = self else { return .anyFail(error: error) }
                
                if let moyaError = error as? MoyaError, case let .statusCode(resp) = moyaError {
                    let message = "Switchable publisher catched error: \(moyaError). Response message: \(String(describing: String(data: resp.data, encoding: .utf8)))"
                    
                    Log.network(message)
                    exceptionHandler?.log(exception: message)
                }
                
                if case WalletError.noAccount = error {
                    return .anyFail(error: error)
                }
                
                let message = "Switchable publisher catched error: \(error)"
                
                Log.network(message)
                exceptionHandler?.log(exception: message)
                
                if self.needRetry(for: currentHost) {
                    let message = "Switching to next publisher"
                    Log.network(message)
                    exceptionHandler?.log(exception: message)
                    
                    return self.providerPublisher(for: requestPublisher)
                }
                
                return .anyFail(error: error)
            }
            .eraseToAnyPublisher()
    }
    
    // NOTE: There also copy of this behaviour in the wild, if you want to update something
    // in the code, don't forget to update also Solano.Swift framework, class NetworkingRouter
    private func needRetry(for errorHost: String) -> Bool {
        if errorHost != self.host { // Do not switch the provider, if it was switched already
            return true
        }
        
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
