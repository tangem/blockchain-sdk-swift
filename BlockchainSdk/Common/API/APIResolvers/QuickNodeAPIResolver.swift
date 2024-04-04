//
//  QuickNodeAPIResolver.swift
//  BlockchainSdk
//
//  Created by Andrew Son on 04/04/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct QuickNodeAPIResolver {
    let config: BlockchainSdkConfig

    func resolve(for blockchain: Blockchain) -> NodeInfo? {
        switch blockchain {
        case .bsc:
            return .init(url: URL(string: "https://\(config.quickNodeBscCredentials.subdomain).bsc.discover.quiknode.pro/\(config.quickNodeBscCredentials.apiKey)")!)
        default:
            return nil
        }
    }
}
