//
//  BlockchainSdkConfig.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 14.12.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public struct BlockchainSdkConfig {
    let blockchairApiKey: String
    let blockcypherTokens: [String]
    let infuraProjectId: String
    
    public init(blockchairApiKey: String, blockcypherTokens: [String], infuraProjectId: String) {
        self.blockchairApiKey = blockchairApiKey
        self.blockcypherTokens = blockcypherTokens
        self.infuraProjectId = infuraProjectId
    }
}
