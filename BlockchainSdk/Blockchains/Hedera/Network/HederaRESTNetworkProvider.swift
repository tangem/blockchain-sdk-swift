//
//  HederaRESTNetworkProvider.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 25.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

/// Provider for Hedera Mirror Nodes (REST) https://docs.hedera.com/hedera/sdks-and-apis/rest-api
struct HederaRESTNetworkProvider {
    private let targetConfiguration: NodeInfo
    private let provider: NetworkProvider<HederaTarget>

    init(
        targetConfiguration: NodeInfo,
        providerConfiguration: NetworkProviderConfiguration
    ) {
        self.targetConfiguration = targetConfiguration
        provider = NetworkProvider<HederaTarget>(configuration: providerConfiguration)
    }

    func getAccounts(publicKey: String) -> some Publisher<HederaNetworkResult.AccountsInfo, Error> {
        return requestPublisher(for: .getAccounts(publicKey: publicKey))
    }

    func getTokens(accountId: String) -> some Publisher<HederaNetworkResult.TokensInfo, Error> {
        return requestPublisher(for: .getTokens(accountId: accountId))
    }

    func getExchangeRates() -> some Publisher<HederaNetworkResult.ExchangeRate, Error> {
        return requestPublisher(for: .getExchangeRate)
    }

    private func requestPublisher<T: Decodable>(
        for target: HederaTarget.Target
    ) -> some Publisher<T, Swift.Error> {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        return provider
            .requestPublisher(HederaTarget(configuration: targetConfiguration, target: target))
            .filterSuccessfulStatusCodes()
            .map(T.self, using: decoder)
            .mapError { moyaError in
                // Trying to convert a network response with 4xx and 5xx status codes to a Hedera API error
                switch moyaError {
                case .statusCode(let response) where response.statusCode >= 400 && response.statusCode < 600:
                    do {
                        return try decoder.decode(HederaNetworkResult.APIError.self, from: response.data)
                    } catch {
                        // Pass-through the original Moya error if conversion failed
                        fallthrough
                    }
                default:
                    return moyaError
                }
            }
    }
}

// MARK: - HostProvider protocol conformance

extension HederaRESTNetworkProvider: HostProvider {
    var host: String {
        targetConfiguration.host
    }
}
