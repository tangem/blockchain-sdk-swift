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
    private let mirrorProviders: [HederaMirrorNetworkProvider]

    init(
        blockchain: Blockchain,
        consensusProvider: HederaConsensusNetworkProvider,
        mirrorProviders: [HederaMirrorNetworkProvider]
    ) {
        self.blockchain = blockchain
        self.consensusProvider = consensusProvider
        self.mirrorProviders = mirrorProviders
        currentProviderIndex = 0
    }
}

// MARK: - MultiNetworkProvider protocol conformance

extension HederaNetworkService: MultiNetworkProvider {
    var providers: [HederaMirrorNetworkProvider] { mirrorProviders }
}
