//
//  GetBlockBlockBookConfig.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 20.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct GetBlockBlockBookConfig {
    private let currencySymbol: String
    private let apiKey: String
    
    private let basicHost = "getblock.io"
    
    init(currencySymbol: String, apiKey: String) {
        self.currencySymbol = currencySymbol
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
        return "\(currencySymbol).\(basicHost)"
    }
    
    func domain(for request: BlockBookTarget.Request, blockchain: Blockchain) -> String {
        let currencySymbolPrefix = currencySymbol
        
        switch request {
        case .fees:
            return "https://\(currencySymbolPrefix).\(basicHost)"
        default:
            return "https://\(currencySymbolPrefix).\(basicHost)"
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
