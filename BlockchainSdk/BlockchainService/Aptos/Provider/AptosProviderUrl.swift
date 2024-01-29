//
//  AptosProviderUrl.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 26.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

enum AptosProviderType {
    case nownodes
    case getblock
}

struct AptosProviderNode: HostProvider {
    var host: String {
        url.hostOrUnknown
    }
    
    let type: AptosProviderType
    let apiKeyValue: String
    
    var url: URL {
        switch type {
        case .getblock:
            return URL(string: "https://go.getblock.io/\(apiKeyValue)/")!
        case .nownodes:
            return URL(string: "https://apt.nownodes.io/")!
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
    
    init(type: AptosProviderType, apiKeyValue: String? = nil) {
        self.type = type
        self.apiKeyValue = apiKeyValue ?? ""
    }
}
