//
//  TransactionHistoryAPIProvider.swift
//  BlockchainSdk
//
//  Created by Andrew Son on 04/04/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct TransactionHistoryAPILinkProvider {
    let config: BlockchainSdkConfig

    func link(for blockchain: Blockchain, providerType: NetworkProviderType?) -> URL? {
        switch providerType {
        case .nowNodes:
            return NownodesTransactionHistoryAPILinkProvider(apiKey: config.nowNodesApiKey)
                .link(for: blockchain)
        default:
            break
        }

        switch blockchain {
        case .algorand(_, let isTestnet):
            return isTestnet ?
            URL(string: "https://testnet-idx.algonode.cloud")! :
            URL(string: "https://mainnet-idx.algonode.cloud")!
        default:
            return nil
        }
    }
}

struct NownodesTransactionHistoryAPILinkProvider {
    let apiKey: String

    func link(for blockchain: Blockchain) -> URL? {
        switch blockchain {
        case .algorand:
            return URL(string: "https://algo-index.nownodes.io")!
        default:
            return nil
        }
    }
}
