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
            return URL(string: "https://algo.nownodes.io/\(apiKeyValue)/")!
        }
    }
    
    var apiKeyHeaderName: String? {
        switch type {
        case .getblock:
            return nil
        case .nownodes:
            return Constants.nowNodesApiKeyHeaderName
        }
    }
    
    init(type: AlgorandProviderType, apiKeyValue: String) {
        self.type = type
        self.apiKeyValue = apiKeyValue
    }
}
