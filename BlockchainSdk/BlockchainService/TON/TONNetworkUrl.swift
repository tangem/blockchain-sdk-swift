//
//  TONNetwork.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 12.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

enum TONEndpointType: Int, CaseIterable {
    case toncenter
    case getblock
    case nownodes
    
    /// Is support testnet type endpoint
    var hasTestnent: Bool {
        switch self {
        case .toncenter:
            return true
        case .getblock, .nownodes:
            return false
        }
    }
    
    func isAvailable(with apiKey: String?) -> Bool {
        switch self {
        case .toncenter:
            return true
        case .getblock, .nownodes:
            return apiKey?.isEmpty == false
        }
    }
    
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
    let isTestnet: Bool
    
    var endpoint: TONEndpoint {
        switch endpointType {
        case .toncenter:
            let url = isTestnet ? URL(string: "https://testnet.toncenter.com/api/v2/")! : URL(string: "https://toncenter.com/api/v2/")!
            
            return TONEndpoint(
                url: url,
                apiKeyHeaderName: Constants.tonCenterApiKeyHeaderName,
                apiKeyHeaderValue: apiKeyValue
            )
        case .getblock:
            return TONEndpoint(url: URL(string: "https://ton.getblock.io/\(apiKeyValue)/mainnet")!)
        case .nownodes:
            return TONEndpoint(url: URL(string: "https://ton.nownodes.io/\(apiKeyValue)")!)
        }
    }
    
    init?(apiKeyValue: String?, endpointType: TONEndpointType, isTestnet: Bool) {
        guard endpointType.isAvailable(with: apiKeyValue) else {
            return nil
        }
        
        // Verify available testnet node
        if isTestnet, !endpointType.hasTestnent {
            return nil
        }
        
        self.apiKeyValue = apiKeyValue ?? ""
        self.endpointType = endpointType
        self.isTestnet = isTestnet
    }
    
}
