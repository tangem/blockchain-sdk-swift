//
//  NowNodesBlockConfig.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 08.02.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

import Foundation

struct NowNodesBlockConfig {
    private let apiKey: String
    private let supportingBlockchains: [Blockchain] = [.ravencoin(testnet: false)]
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
}

extension NowNodesBlockConfig: BlockBookConfig {
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
        guard supportingBlockchains.contains(blockchain) else {
            assertionFailure("NowNodesBlockConfig don't support \(blockchain.displayName)")
            return ""
        }
        
        let currencySymbolPrefix = blockchain.currencySymbol.lowercased()
        return "https://\(currencySymbolPrefix).\(host)"
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
