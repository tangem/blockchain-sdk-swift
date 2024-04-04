//
//  NownodesAPIResolver.swift
//  BlockchainSdk
//
//  Created by Andrew Son on 04/04/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct NownodesAPIResolver {
    let apiKey: String

    func resolve(for blockchain: Blockchain) -> NodeInfo? {
        if blockchain.isTestnet {
            if case .ethereum = blockchain { } else {
                return nil
            }
        }

        let link: String
        switch blockchain {
        case .ethereum(let isTestnet):
            link = isTestnet ? "https://eth-goerli.nownodes.io/\(apiKey)" : "https://eth.nownodes.io/\(apiKey)"
        case .cosmos:
            link = "https://atom.nownodes.io/\(apiKey)"
        case .terraV1:
            link = "https://lunc.nownodes.io/\(apiKey)"
        case .terraV2:
            link = "https://luna.nownodes.io/\(apiKey)"
        case .near:
            link = "https://near.nownodes.io/\(apiKey)"
        case .stellar:
            link = "https://xlm.nownodes.io/\(apiKey)"
        case .ton:
            link = "https://ton.nownodes.io/\(apiKey)"
        case .tron:
            link = "https://trx.nownodes.io"
        case .veChain:
            link = "https://vet.nownodes.io/\(apiKey)"
        case .algorand:
            link = "https://algo.nownodes.io"
        case .aptos:
            link = "https://apt.nownodes.io"
        case .xrp:
            link = "https://xrp.nownodes.io"
        case .avalanche:
            link = "https://avax.nownodes.io/\(apiKey)/ext/bc/C/rpc"
        case .ethereumPoW:
            link = "https://ethw.nownodes.io/\(apiKey)"
        case .rsk:
            link = "https://rsk.nownodes.io/\(apiKey)"
        case .bsc:
            link = "https://bsc.nownodes.io/\(apiKey)"
        case .polygon:
            link = "https://matic.nownodes.io/\(apiKey)"
        case .fantom:
            link = "https://ftm.nownodes.io/\(apiKey)"
        case .arbitrum:
            link = "https://arbitrum.nownodes.io/\(apiKey)"
        case .optimism:
            link = "https://optimism.nownodes.io/\(apiKey)"
        case .xdc:
            link = "https://xdc.nownodes.io/\(apiKey)"
        case .shibarium:
            link = "https://shib.nownodes.io/\(apiKey)"
        case .zkSync:
            link = "https://zksync.nownodes.io/\(apiKey)"
        case .moonbeam:
            link = "https://moonbeam.nownodes.io/\(apiKey)"
        default:
            return nil
        }

        let apiKeyInfoProvider = NownodesAPIKeysInfoProvider(apiKey: apiKey)
        guard let url = URL(string: link) else {
            return nil
        }

        return .init(
            url: url,
            keyInfo: apiKeyInfoProvider.apiKeys(for: blockchain)
        )
    }
}

struct NownodesAPIKeysInfoProvider {
    let apiKey: String
    func apiKeys(for blockchain: Blockchain) -> APIKeyInfo? {
        switch blockchain {
        case .xrp, .tron, .algorand, .aptos:
            return .init(
                headerName: Constants.nowNodesApiKeyHeaderName,
                headerValue: apiKey
            )
        default: return nil
        }
    }
}
