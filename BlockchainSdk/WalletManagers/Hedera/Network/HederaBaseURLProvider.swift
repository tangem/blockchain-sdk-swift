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

    func baseURLs() -> [HederaBaseURLConfig] {
        var baseURLs: [HederaBaseURLConfig] = []

        if isTestnet {
            baseURLs.append(
                contentsOf: [
                    HederaBaseURLConfig(
                        helperNodeBaseURL: URL(string: "about:blank")!, // TODO: Andrey Fedorov - Add actual implementation (IOS-5888)
                        mirrorNodeBaseURL: URL(string: "https://testnet.mirrornode.hedera.com")!
                    ),
                ]
            )
        } else {
            baseURLs.append(
                contentsOf: [
                    HederaBaseURLConfig(
                        helperNodeBaseURL: URL(string: "about:blank")!, // TODO: Andrey Fedorov - Add actual implementation (IOS-5888)
                        mirrorNodeBaseURL: URL(string: "https://mainnet-public.mirrornode.hedera.com")!
                    ),
                ]
            )
        }

        return baseURLs
    }
}
