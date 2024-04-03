//
//  TONNetworkNode.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 12.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct APIKeyInfo {
    let headerName: String
    let headerValue: String
}

struct TONNetworkNode {
    let url: URL
    let apiKeyInfo: APIKeyInfo?
    
    init(url: URL, apiKeyInfo: APIKeyInfo? = nil) {
        self.url = url
        self.apiKeyInfo = apiKeyInfo
    }
}
