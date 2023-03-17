//
//  GetBlockBlockBookConfig.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 20.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct GetBlockBlockBookConfig {
    private let apiKey: String
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
}

extension GetBlockBlockBookConfig: BlockBookConfig {
    var apiKeyValue: String {
        return apiKey
    }
    
    var apiKeyName: String {
        return Constants.xApiKeyHeaderName
    }
    
    var host: String {
        return "getblock.io"
    }
    
    func domain(for request: BlockBookTarget.Request, blockchain: Blockchain) -> String {
        let currencySymbolPrefix = blockchain.currencySymbol.lowercased()
        
        switch request {
        case .fees:
            return "https://\(currencySymbolPrefix).\(host)"
        default:
            return "https://\(currencySymbolPrefix).\(host)"
        }
    }
    
    func path(for request: BlockBookTarget.Request) -> String {
        switch request {
        case .fees:
            return "/mainnet"
        default:
            return "/mainnet/blockbook/api/v2"
        }
    }
}
