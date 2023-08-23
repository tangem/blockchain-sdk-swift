//
//  BlockBookConfig.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 20.12.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

protocol BlockBookConfig {
    var apiKeyValue: String { get }
    var apiKeyName: String { get }
    var host: String { get }
    
    func node(for blockchain: Blockchain) -> NodeConfig
    func path(for request: BlockBookTarget.Request) -> String
}

struct NodeConfig {
    let rpcNode: String
    let restNode: String
}
