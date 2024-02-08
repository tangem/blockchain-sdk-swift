//
//  HederaNetworkService.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 25.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

final class HederaNetworkService {
    var currentProviderIndex: Int

    private let blockchain: Blockchain
    private let consensusProvider: HederaConsensusNetworkProvider
    private let restProviders: [HederaRESTNetworkProvider]

    init(
        blockchain: Blockchain,
        consensusProvider: HederaConsensusNetworkProvider,
        restProviders: [HederaRESTNetworkProvider]
    ) {
        self.blockchain = blockchain
        self.consensusProvider = consensusProvider
        self.restProviders = restProviders
        currentProviderIndex = 0
    }
}

// MARK: - MultiNetworkProvider protocol conformance

extension HederaNetworkService: MultiNetworkProvider {
    var providers: [HederaRESTNetworkProvider] { restProviders }
}
