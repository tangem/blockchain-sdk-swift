//
//  HederaBaseURLProvider.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 02.02.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct HederaBaseURLProvider {
    let isTestnet: Bool

    func baseURLs() -> [URL] {
        var baseURLStrings: [String] = []

        if isTestnet {
            baseURLStrings.append(
                contentsOf: [
                    "https://testnet.mirrornode.hedera.com",
                ]
            )
        } else {
            baseURLStrings.append(
                contentsOf: [
                    "https://mainnet-public.mirrornode.hedera.com",
                ]
            )
        }

        return baseURLStrings
            .map { URL(string: $0)! }
    }
}
