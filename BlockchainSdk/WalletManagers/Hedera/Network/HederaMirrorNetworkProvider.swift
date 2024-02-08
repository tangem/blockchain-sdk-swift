//
//  HederaMirrorNetworkProvider.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 25.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

// TODO: Andrey Fedorov - Add actual implementation (IOS-4556)
/// Provider for Hedera Mirror Nodes (REST) https://docs.hedera.com/hedera/sdks-and-apis/rest-api
struct HederaMirrorNetworkProvider {
    private let baseURL: URL
    private let provider: NetworkProvider<HederaTarget>

    init(
        baseURL: URL,
        configuration: NetworkProviderConfiguration
    ) {
        self.baseURL = baseURL
        provider = NetworkProvider<HederaTarget>(configuration: configuration)
    }
}

// MARK: - HostProvider protocol conformance

extension HederaMirrorNetworkProvider: HostProvider {
    var host: String {
        return baseURL.hostOrUnknown
    }
}
