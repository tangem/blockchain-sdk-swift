//
//  GetBlockBlockBookConfig.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 20.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct GetBlockBlockBookConfig: BlockBookConfig {
    var apiKeyHeaderName: String?
    var apiKeyHeaderValue: String?
    
    private let values: [Blockchain: String]
    
    init(_ values: [Blockchain: String]) {
        self.values = values
    }
}

extension GetBlockBlockBookConfig {
    
    var apiKeyValue: String { "" }
    var apiKeyName: String { "" }
    
    var host: String {
        return "getblock.io"
    }
    
    func node(for blockchain: Blockchain) -> BlockBookNode {
        let apiKeyValue = values[blockchain] ?? ""
        
        return BlockBookNode(
            rpcNode: "https://go.\(host)/\(apiKeyValue)",
            restNode: "https://go.\(host)/\(apiKeyValue)"
        )
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
