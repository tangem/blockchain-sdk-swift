//
//  TONNetwork.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 12.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

enum TONEndpointType {
    case toncenter(_ testnet: Bool)
    case getblock(_ key: String)
    case nownodes
}

struct TONEndpoint {
    public let url: URL
    
    public let apiKeyHeaderName: String?
    public let apiKeyHeaderValue: String?
    
    public init(url: URL, apiKeyHeaderName: String? = nil, apiKeyHeaderValue: String? = nil) {
        self.url = url
        
        self.apiKeyHeaderName = apiKeyHeaderName
        self.apiKeyHeaderValue = apiKeyHeaderValue
    }
}

struct TONNetworkNode {
    
    let apiKeyValue: String
    let endpointType: TONEndpointType
    
    var endpoint: TONEndpoint {
        switch endpointType {
        case .toncenter(let testnet):
            let url = testnet ? URL(string: "https://testnet.toncenter.com/api/v2/")! : URL(string: "https://toncenter.com/api/v2/")!
            
            return TONEndpoint(
                url: url,
                apiKeyHeaderName: Constants.xApiKeyHeaderName,
                apiKeyHeaderValue: apiKeyValue
            )
        case .getblock(let apiKeyValue):
            return TONEndpoint(url: URL(string: "https://go.getblock.io/\(apiKeyValue)")!)
        case .nownodes:
            return TONEndpoint(url: URL(string: "https://ton.nownodes.io/\(apiKeyValue)")!)
        }
    }
    
    init(apiKeyValue: String? = nil, endpointType: TONEndpointType) {
        self.apiKeyValue = apiKeyValue ?? ""
        self.endpointType = endpointType
    }
    
}
