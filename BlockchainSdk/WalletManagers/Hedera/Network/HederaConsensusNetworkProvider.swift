//
//  HederaConsensusNetworkProvider.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 03.02.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

// TODO: Andrey Fedorov - Add actual implementation (IOS-4556)
/// Provider for Hedera Consensus Nodes (GRPC) https://docs.hedera.com/hedera/networks/mainnet/mainnet-nodes
struct HederaConsensusNetworkProvider {
    private let configuration: NetworkProviderConfiguration

    init(
        configuration: NetworkProviderConfiguration
    ) {
        self.configuration = configuration
    }
}
