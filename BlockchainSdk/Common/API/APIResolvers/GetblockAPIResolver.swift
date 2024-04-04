//
//  GetblockAPIResolver.swift
//  BlockchainSdk
//
//  Created by Andrew Son on 04/04/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct GetblockAPIResolver {
    let credentials: BlockchainSdkConfig.GetBlockCredentials

    func resolve(for blockchain: Blockchain) -> NodeInfo? {
        if blockchain.isTestnet {
            return nil
        }

        let link: String
        switch blockchain {
        case .cosmos, .tron, .algorand, .aptos:
            link = "https://go.getblock.io/\(credentials.credential(for: blockchain, type: .rest))"
        case .near, .ton, .ethereum, .ethereumClassic, .rsk, .bsc, .polygon, .fantom, .gnosis, .cronos, .zkSync, .moonbeam, .polygonZkEVM:
            link =  "https://go.getblock.io/\(credentials.credential(for: blockchain, type: .jsonRpc))"
        case .cardano:
            link = "https://go.getblock.io/\(credentials.credential(for: blockchain, type: .rosetta))"
        case .avalanche:
            link = "https://go.getblock.io/\(credentials.credential(for: blockchain, type: .jsonRpc))/ext/bc/C/rpc"
        default:
            return nil
        }

        guard let url = URL(string: link) else {
            return nil
        }

        return .init(url: url)
    }
}
