//
//  VeChainNetworkProvider.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 18.12.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

struct VeChainNetworkProvider {
    private let baseURL: URL
    private let provider: NetworkProvider<VeChainTarget>

    init(
        baseURL: URL,
        configuration: NetworkProviderConfiguration
    ) {
        self.baseURL = baseURL
        provider = NetworkProvider<VeChainTarget>(configuration: configuration)
    }

    func getAccountInfo(address: String) -> AnyPublisher<VeChainNetworkResult.AccountInfo, Error> {
        return requestPublisher(for: .viewAccount(address: address))
    }

    func sendTransaction(
        _ rawTransaction: String
    ) -> AnyPublisher<VeChainNetworkResult.Transaction, Error> {
        return requestPublisher(for: .sendTransaction(rawTransaction: rawTransaction))
    }

    func getTransactionStatus(
        transactionHash: String,
        includePending: Bool,
        rawOutput: Bool
    ) -> AnyPublisher<VeChainNetworkResult.TransactionStatus, Error> {
        return requestPublisher(
            for: .transactionStatus(transactionHash: transactionHash, includePending: includePending, rawOutput: rawOutput)
        )
    }

    private func requestPublisher<T: Decodable>(
        for target: VeChainTarget.Target
    ) -> AnyPublisher<T, Swift.Error> {
        return provider.requestPublisher(VeChainTarget(baseURL: baseURL, target: target))
            .filterSuccessfulStatusCodes()
            .map(T.self)
            .mapError { moyaError -> Swift.Error in
                switch moyaError {
                case .jsonMapping,
                        .objectMapping:
                    return WalletError.failedToParseNetworkResponse
                case .imageMapping,
                        .stringMapping,
                        .encodableMapping,
                        .statusCode,
                        .underlying,
                        .requestMapping,
                        .parameterEncoding:
                    return moyaError
                @unknown default:
                    assertionFailure("Unknown error kind received: \(moyaError)")
                    return moyaError
                }
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - HostProvider protocol conformance

extension VeChainNetworkProvider: HostProvider {
    var host: String {
        baseURL.hostOrUnknown
    }
}
