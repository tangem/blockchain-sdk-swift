//
//  GetBlockBlockBookConfig.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 20.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct GetBlockBlockBookConfig: BlockBookConfig {
    let rawValue: BlockBookConfigTypeValue
    
    init(_ rawValue: BlockBookConfigTypeValue) {
        self.rawValue = rawValue
    }
}

extension GetBlockBlockBookConfig {
    
    var host: String {
        return "getblock.io"
    }
    
    func node(for blockchain: Blockchain) -> BlockBookNode {
        if case .host(let values) = rawValue {
            if let apiKeyValue = values[blockchain] {
                return BlockBookNode(
                    rpcNode: "https://go.\(host)/\(apiKeyValue)",
                    restNode: "https://go.\(host)/\(apiKeyValue)"
                )
            } else {
                fatalError("GetBlockBlockBookConfig don't support blockchain: \(blockchain.displayName)")
            }
        }
        
        fatalError("NowNodesBlockBookConfig don't support HEADER API KEY value type blockchain: \(blockchain.displayName)")
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
