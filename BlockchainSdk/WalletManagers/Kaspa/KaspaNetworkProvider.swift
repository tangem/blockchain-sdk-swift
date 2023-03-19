//
//  KaspaNetworkProvider.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 10.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class KaspaNetworkProvider: HostProvider {
    var host: String {
        url.hostOrUnknown
    }
    
    private let url: URL
    private let blockchain: Blockchain
    private let provider: NetworkProvider<KaspaTarget>
    
    init(url: URL, blockchain: Blockchain, networkConfiguration: NetworkProviderConfiguration) {
        self.url = url
        self.blockchain = blockchain
        self.provider = NetworkProvider<KaspaTarget>(configuration: networkConfiguration)
    }
    
    func balance(address: String) -> AnyPublisher<KaspaBalanceResponse, Error> {
        requestPublisher(for: .balance(address: address))
    }
    
    func utxos(address: String) -> AnyPublisher<[KaspaUnspentOutputResponse], Error> {
        requestPublisher(for: .utxos(address: address))
    }
    
    func send(transaction: KaspaTransactionRequest) -> AnyPublisher<KaspaTransactionResponse, Error> {
        requestPublisher(for: .transactions(transaction: transaction))
    }
    
    private func requestPublisher<T: Codable>(for request: KaspaTarget.Request) -> AnyPublisher<T, Error> {
        return provider.requestPublisher(KaspaTarget(request: request, baseURL: url))
            .filterSuccessfulStatusAndRedirectCodes()
            .map(T.self)
            .mapError { moyaError in
                if case .objectMapping = moyaError {
                    return WalletError.failedToParseNetworkResponse
                }
                return moyaError
            }
            .eraseToAnyPublisher()
    }
}
