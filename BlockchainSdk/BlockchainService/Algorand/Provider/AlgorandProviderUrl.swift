//
//  AlgorandNetworkUrl.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 10.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

enum AlgorandProviderType {
    // This type node for main flow blockchain api
    case nownodes
    case getblock
    case fullNode(isTestnet: Bool)
    
    // This type node for transaction history api
    case idxNownodes
    case idxFullNode(isTestnet: Bool)
}

struct AlgorandProviderNode: HostProvider {
    var host: String {
        url.hostOrUnknown
    }
    
    let type: AlgorandProviderType
    let apiKeyValue: String
    
    var url: URL {
        switch type {
        case .getblock:
            return URL(string: "https://go.getblock.io/\(apiKeyValue)/")!
        case .nownodes:
            return URL(string: "https://algo.nownodes.io/")!
        case .fullNode(let isTestnet):
            if isTestnet {
                return URL(string: "https://mainnet-api.algonode.cloud/")!
            } else {
                return URL(string: "https://mainnet-api.algonode.cloud/")!
            }
        case .idxFullNode(let isTestnet):
            if isTestnet {
                return URL(string: "https://testnet-idx.algonode.cloud/")!
            } else {
                return URL(string: "https://mainnet-idx.algonode.cloud/")!
            }
        case .idxNownodes:
            return URL(string: "https://algo-index.nownodes.io/")!
        }
    }
    
    var apiKeyHeaderName: String? {
        switch type {
        case .getblock, .fullNode, .idxFullNode:
            return nil
        case .nownodes, .idxNownodes:
            return Constants.nowNodesApiKeyHeaderName
        }
    }
    
    init(type: AlgorandProviderType, apiKeyValue: String? = nil) {
        self.type = type
        self.apiKeyValue = apiKeyValue ?? ""
    }
}
