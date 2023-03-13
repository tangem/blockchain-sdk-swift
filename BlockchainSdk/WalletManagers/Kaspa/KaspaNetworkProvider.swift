//
//  KaspaNetworkProvider.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 10.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class KaspaNetworkProvider {
    var host: String {
        url.hostOrUnknown
    }
    
    var supportsTransactionPush: Bool {
        false
    }
    
    private let url: URL
    private let blockchain: Blockchain
    private let provider: NetworkProvider<KaspaTarget>
    
    init(url: URL, blockchain: Blockchain, networkConfiguration: NetworkProviderConfiguration) {
        self.url = url
        self.blockchain = blockchain
        self.provider = NetworkProvider<KaspaTarget>(configuration: networkConfiguration)
    }
    
    private func balance(address: String) -> AnyPublisher<KaspaBalanceResponse, Error> {
        requestPublisher(for: .balance(address: address))
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

extension KaspaNetworkProvider: BitcoinNetworkProvider {
    func getInfo(address: String) -> AnyPublisher<BitcoinResponse, Error> {
        balance(address: address)
            .tryMap { [weak self] balance in
                guard let self else { throw WalletError.empty }
                
                return BitcoinResponse(
                    balance: Decimal(integerLiteral: balance.balance) / self.blockchain.decimalValue,
                    hasUnconfirmed: false,
                    pendingTxRefs: [],
                    unspentOutputs: []
                )
            }
            .eraseToAnyPublisher()
    }
    
    func getFee() -> AnyPublisher<BitcoinFee, Error> {
        // TODO
        .anyFail(error: WalletError.empty)
    }
    
    func send(transaction: String) -> AnyPublisher<String, Error> {
        // TODO
        .anyFail(error: WalletError.empty)
    }
    
    func push(transaction: String) -> AnyPublisher<String, Error> {
        // TODO
        .anyFail(error: WalletError.empty)
    }
    
    func getSignatureCount(address: String) -> AnyPublisher<Int, Error> {
        // TODO
        .anyFail(error: WalletError.empty)
    }
}
