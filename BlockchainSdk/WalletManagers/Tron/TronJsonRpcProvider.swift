//
//  TronJsonRpcProvider.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 24.03.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Moya

class TronJsonRpcProvider: HostProvider {
    var host: String {
        network.url.hostOrUnknown
    }

    private let network: TronNetwork
    private let provider = MoyaProvider<TronTarget>(plugins: [NetworkLoggerPlugin()])
    
    init(network: TronNetwork) {
        self.network = network
    }

    func getAccount(for address: String) -> AnyPublisher<TronGetAccountResponse, Error> {
        requestPublisher(for: .getAccount(address: address, network: network))
    }
    
    func createTransaction(from source: String, to destination: String, amount: UInt64) -> AnyPublisher<TronTransactionRequest, Error> {
        requestPublisher(for: .createTransaction(source: source, destination: destination, amount: amount, network: network))
    }
    
    private func requestPublisher<T: Codable>(for target: TronTarget) -> AnyPublisher<T, Error> {
        return provider.requestPublisher(target)
            .filterSuccessfulStatusAndRedirectCodes()
            .map(T.self)
            .catch { _ -> AnyPublisher<T, Error> in
                // TODO
                return .anyFail(error: WalletError.failedToParseNetworkResponse)
            }
            .eraseToAnyPublisher()
    }
}
