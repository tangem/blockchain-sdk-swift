//
//  ChiaNetworkUrl.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 14.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

enum ChiaEndpointType {
    case fireAcademy(isTestnet: Bool)
    case tangem
}

struct ChiaNetworkEndpoint {
    public let url: URL
    public let apiKeyValue: String?
    
    init(url: URL, apiKeyValue: String?) {
        self.url = url
        self.apiKeyValue = apiKeyValue
    }
}

struct ChiaNetworkNode {
    let apiKeyValue: String
    let endpointType: ChiaEndpointType
    
    var endpoint: ChiaNetworkEndpoint {
        switch endpointType {
        case .fireAcademy(let testnet):
            let url = testnet ?
                URL(string: "https://kraken.fireacademy.io/leaflet-testnet10/")! :
                URL(string: "https://kraken.fireacademy.io/leaflet/")!
            return ChiaNetworkEndpoint(url: url, apiKeyValue: apiKeyValue)
        case .tangem:
            let url = URL(string: "https://chia.tangem.com/")!
            return ChiaNetworkEndpoint(url: url, apiKeyValue: apiKeyValue)
        }
    }
    
    init(apiKeyValue: String, endpointType: ChiaEndpointType) {
        self.apiKeyValue = apiKeyValue
        self.endpointType = endpointType
    }
}
