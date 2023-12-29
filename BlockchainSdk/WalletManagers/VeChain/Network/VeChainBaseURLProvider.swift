//
//  VeChainBaseURLProvider.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 18.12.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct VeChainBaseURLProvider {
    let isTestnet: Bool
    let sdkConfig: BlockchainSdkConfig

    func baseURLs() -> [URL] {
        var baseURLStrings: [String] = []

        if isTestnet {
            baseURLStrings.append(
                contentsOf: [
                    "https://testnet.vecha.in",
                    "https://sync-testnet.vechain.org",
                    "https://testnet.veblocks.net",
                    "https://testnetc1.vechain.network",
                ]
            )
        } else {
            baseURLStrings.append(
                contentsOf: [
                    "https://mainnet.vecha.in",
                    "https://sync-mainnet.vechain.org",
                    "https://vet.nownodes.io/\(sdkConfig.nowNodesApiKey)",
                    "https://mainnet.veblocks.net",
                    "https://mainnetc1.vechain.network",
                    "https://us.node.vechain.energy",
                ]
            )
        }

        return baseURLStrings
            .map { URL(string: $0)! }
    }
}
