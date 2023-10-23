//
//  NEARNetworkProvider.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 13.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

struct NEARNetworkProvider {
    private let baseURL: URL
    private let provider: NetworkProvider<NEARTarget>

    init(
        baseURL: URL,
        configuration: NetworkProviderConfiguration
    ) {
        self.baseURL = baseURL
        provider = NetworkProvider<NEARTarget>(configuration: configuration)
    }

    func getProtocolConfig() -> AnyPublisher<JSONRPCResult<NEARNetworkResult.ProtocolConfig>, Error> {
        return requestPublisher(for: .protocolConfig)
    }

    func getGasPrice() -> AnyPublisher<JSONRPCResult<NEARNetworkResult.GasPrice>, Error> {
        return requestPublisher(for: .gasPrice)
    }

    func getInfo(
        accountId: String
    ) -> AnyPublisher<JSONRPCResult<NEARNetworkResult.AccountInfo>, Error> {
        return requestPublisher(for: .viewAccount(accountId: accountId))
    }

    func getAccessKeyInfo(
        accountId: String,
        publicKey: String
    ) -> AnyPublisher<JSONRPCResult<NEARNetworkResult.AccessKeyInfo>, Error> {
        return requestPublisher(for: .viewAccessKey(accountId: accountId, publicKey: publicKey))
    }

    func sendTransactionAsync(
        _ transaction: String
    ) -> AnyPublisher<JSONRPCResult<NEARNetworkResult.TransactionSendAsync>, Error> {
        return requestPublisher(for: .sendTransactionAsync(transaction: transaction))
    }

    func sendTransactionAwait(
        _ transaction: String
    ) -> AnyPublisher<JSONRPCResult<NEARNetworkResult.TransactionSendAwait>, Error> {
        return requestPublisher(for: .sendTransactionAwait(transaction: transaction))
    }

    private func requestPublisher<T: Decodable>(
        for target: NEARTarget.Target
    ) -> AnyPublisher<T, Error> {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        return provider.requestPublisher(NEARTarget(baseURL: baseURL, target: target))
            .filterSuccessfulStatusCodes()
            .map(T.self, using: decoder)
            .mapError { moyaError in
                // TODO: Andrey Fedorov - Map to NEAR API JSON-RPC errors if needed (https://docs.near.org/api/rpc/contracts#what-could-go-wrong)
                return WalletError.failedToParseNetworkResponse
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - HostProvider protocol conformance

extension NEARNetworkProvider: HostProvider {
    var host: String {
        baseURL.hostOrUnknown
    }
}
