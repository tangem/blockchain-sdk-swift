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
}

private typealias SwitchedNetworkProviderParams = (nextHost: String, isSwitched: Bool)

extension MultiNetworkProvider {
    var provider: Provider {
        providers[currentProviderIndex]
    }
    
    var host: String { provider.host }
    
    func providerPublisher<T>(for requestPublisher: @escaping (_ provider: Provider) -> AnyPublisher<T, Error>) -> AnyPublisher<T, Error> {
        let currentHost = self.host
        
        return requestPublisher(provider)
            .catch { [weak self] error -> AnyPublisher<T, Error> in
                guard let self = self else { return .anyFail(error: error) }
                
                if let moyaError = error as? MoyaError, case let .statusCode(resp) = moyaError {
                    Log.network("Switchable publisher catched error: \(moyaError). Response message: \(String(describing: String(data: resp.data, encoding: .utf8)))")
                }
                
                if case WalletError.noAccount = error {
                    return .anyFail(error: error)
                }
                
                Log.network("Switchable publisher catched error: \(error)")
                
                if let providerParams = self.switchProviderIfNeeded(for: currentHost) {
                    // Send event if api did switched by host value
                    
                    if providerParams.isSwitched {
                        Log.network("Switching to next publisher on host")
                        
                        ExceptionHandler.shared.handleAPISwitch(
                            currentHost: currentHost,
                            nextHost: providerParams.nextHost,
                            message: error.localizedDescription
                        )
                    }
                    
                    return self.providerPublisher(for: requestPublisher)
                }
                
                return .anyFail(error: error)
            }
            .eraseToAnyPublisher()
    }
    
    // NOTE: There also copy of this behaviour in the wild, if you want to update something
    // in the code, don't forget to update also Solano.Swift framework, class NetworkingRouter
    /// - Returns: Return of tuple value with next host provider and flag did switch api
    private func switchProviderIfNeeded(for errorHost: String) -> SwitchedNetworkProviderParams? {
        print(self.host)
        print(errorHost)
        
        if errorHost != self.host { // Do not switch the provider, if it was switched already
            return (providers[currentProviderIndex].host, false)
        }
        
        currentProviderIndex += 1
        if currentProviderIndex < providers.count {
            return (providers[currentProviderIndex].host, true)
        }
        resetProviders()
        return nil
    }
    
    private func resetProviders() {
        currentProviderIndex = 0
    }
    
}
