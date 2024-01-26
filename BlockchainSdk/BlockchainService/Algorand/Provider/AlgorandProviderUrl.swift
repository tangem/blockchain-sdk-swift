//
//  AlgorandNetworkUrl.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 10.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

enum AlgorandProviderType {
    case nownodes
    case getblock
    case algoIdx(isTestnet: Bool)
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
        case .algoIdx(let isTestnet):
            if isTestnet {
                return URL(string: "https://testnet-idx.algonode.cloud/")!
            } else {
                return URL(string: "https://mainnet-idx.algonode.cloud/")!
            }
        }
    }
    
    var apiKeyHeaderName: String? {
        switch type {
        case .getblock:
            return nil
        case .nownodes:
            return Constants.nowNodesApiKeyHeaderName
        case .algoIdx:
            return nil
        }
    }
    
    init(type: AlgorandProviderType, apiKeyValue: String? = nil) {
        self.type = type
        self.apiKeyValue = apiKeyValue ?? ""
    }
}
