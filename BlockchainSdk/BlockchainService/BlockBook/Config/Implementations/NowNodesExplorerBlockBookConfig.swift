//
//  NowNodesExplorerBlockBookConfig.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 17.08.2023.
//

import Foundation

/// https://nownodes.io/nodes
struct NowNodesExplorerBlockBookConfig {
    private let apiKey: String
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
}

extension NowNodesExplorerBlockBookConfig: BlockBookConfig {
    var apiKeyValue: String {
        return apiKey
    }
    
    var apiKeyName: String {
        return Constants.nowNodesApiKeyHeaderName
    }
    
    var host: String {
        return "nownodes.io"
    }
    
    func domain(for request: BlockBookTarget.Request, blockchain: Blockchain) -> String {
        let currencySymbolPrefix = blockchain.currencySymbol.lowercased()
        return "https://\(currencySymbolPrefix)-blockbook.\(host)"
    }
    
    func path(for request: BlockBookTarget.Request) -> String {
        return "/api/v2"
    }
}
