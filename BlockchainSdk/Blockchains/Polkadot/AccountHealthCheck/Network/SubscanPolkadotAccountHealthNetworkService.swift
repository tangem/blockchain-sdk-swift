//
//  SubscanPolkadotAccountHealthNetworkService.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 25.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public final class SubscanPolkadotAccountHealthNetworkService {
    private let provider = NetworkProvider<SubscanAPITarget>()
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let isTestnet: Bool
    private let pageSize: Int

    public init(
        isTestnet: Bool,
        pageSize: Int
    ) {
        self.isTestnet = isTestnet
        self.pageSize = pageSize

        encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase

        decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
    }

    public func getAccountHealthInfo(account: String) async throws -> PolkadotAccountHealthInfo {
        let result = try await provider
            .asyncRequest(
                for: .init(
                    isTestnet: isTestnet,
                    encoder: encoder,
                    target: .getAccountInfo(address: account)
                )
            )
            .filterSuccessfulStatusAndRedirectCodes()
            .map(SubscanAPIResult.AccountInfo.self, using: decoder)
            .data
            .account

        return PolkadotAccountHealthInfo(extrinsicCount: result.countExtrinsic, nonceCount: result.nonce)
    }
    
    public func getTransactionsList(account: String, afterId: Int) async throws -> [PolkadotTransaction] {
        let result = try await provider
            .asyncRequest(
                for: .init(
                    isTestnet: isTestnet,
                    encoder: encoder,
                    target: .getExtrinsicsList(
                        address: account,
                        afterId: afterId,
                        page: Constants.startPage,
                        limit: pageSize
                    )
                )
            )
            .filterSuccessfulStatusAndRedirectCodes()
            .map(SubscanAPIResult.ExtrinsicsList.self, using: decoder)
            .data
            .extrinsics

        return result?.map { PolkadotTransaction(id: $0.id, hash: $0.extrinsicHash) } ?? []
    }
    
    public func getTransactionDetails(hash: String) async throws -> PolkadotTransactionDetails {
        let result = try await provider
            .asyncRequest(
                for: .init(
                    isTestnet: isTestnet,
                    encoder: encoder,
                    target: .getExtrinsicInfo(hash: hash)
                )
            )
            .filterSuccessfulStatusAndRedirectCodes()
            .map(SubscanAPIResult.ExtrinsicInfo.self, using: decoder)
            .data
            .lifetime

        return PolkadotTransactionDetails(birth: result?.birth, death: result?.death)
    }
}

// MARK: - Constants

private extension SubscanPolkadotAccountHealthNetworkService {
    enum Constants {
        // - Note: Subscan API has zero-based indexing
        static let startPage = 0
    }
}
