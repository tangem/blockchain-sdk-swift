//
//  VeChainNetworkProvider.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 18.12.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

// TODO: Andrey Fedorov - Add actual implementation (IOS-5239)
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
}

// MARK: - HostProvider protocol conformance

extension VeChainNetworkProvider: HostProvider {
    var host: String {
        baseURL.hostOrUnknown
    }
}
