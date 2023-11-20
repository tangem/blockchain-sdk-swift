//
//  BlockBookConfig.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 20.12.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

protocol BlockBookConfig {
    var rawValue: BlockBookConfigTypeValue { get }
    var host: String { get }
    
    init(_ value: BlockBookConfigTypeValue)
    
    func node(for blockchain: Blockchain) -> BlockBookNode
    func path(for request: BlockBookTarget.Request) -> String
}

enum BlockBookConfigTypeValue {
    case host(_ values: [Blockchain: String])
    case header(name: String, value: String)
}
