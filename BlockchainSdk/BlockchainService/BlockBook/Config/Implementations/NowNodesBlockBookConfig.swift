//
//  NowNodesBlockBookConfig.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 20.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

// https://nownodes.io/nodes
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
    
    func node(for blockchain: Blockchain) -> NodeConfig {
        var currencySymbolPrefix = blockchain.currencySymbol.lowercased()
        
        switch blockchain {
        case .bitcoin, .dash, .dogecoin, .litecoin:
            let testnetSuffix = blockchain.isTestnet ? "-testnet" : ""
            return NodeConfig(
                rpcNode: "https://\(currencySymbolPrefix).\(host)",
                restNode: "https://\(currencySymbolPrefix)book\(testnetSuffix).\(host)"
            )
        case .ethereum, .ethereumPoW, .bsc, .ethereumClassic, .avalanche, .tron, .arbitrum:
            if case .bsc = blockchain {
                currencySymbolPrefix = "bsc"
            }
            
            return NodeConfig(
                rpcNode: "https://\(currencySymbolPrefix).\(host)",
                restNode: "https://\(currencySymbolPrefix)-blockbook.\(host)"
            )
        default:
            fatalError("NowNodesBlockBookConfig don't support blockchain: \(blockchain.displayName)")
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
