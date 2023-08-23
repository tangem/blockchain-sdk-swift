//
//  NowNodesBlockBookConfig.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 20.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct NowNodesBlockBookConfig {
    private let apiKey: String
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
}

extension NowNodesBlockBookConfig: BlockBookConfig {
    
    var apiKeyValue: String {
        return apiKey
    }
    
    var apiKeyName: String {
        return Constants.nowNodesApiKeyHeaderName
    }
    
    var host: String {
        return "nownodes.io"
    }
    
    func domain(for request: BlockBookTarget.Request, prefix: String, isTestnet: Bool) -> String {
        switch request {
        case .fees:
            return "https://\(prefix).\(host)"
        default:
            let testnetSuffix = isTestnet ? "-testnet" : ""
            return "https://\(prefix)book\(testnetSuffix).\(host)"
        }
    }
    
    func path(for request: BlockBookTarget.Request) -> String {
        switch request {
        case .fees:
            return ""
        default:
            return "/api/v2"
        }
    }
}
