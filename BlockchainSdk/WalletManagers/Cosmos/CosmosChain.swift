//
//  CosmosChain.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 10.04.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

enum CosmosChain {
    case cosmos(testnet: Bool)
}

extension CosmosChain {
    var smallestDenomination: String {
        switch self {
        case .cosmos(let testnet):
            assert(testnet)
            return testnet ? "uatom" : "!!! TODO !!!"
        }
    }
    
    var blockchain: Blockchain {
        switch self {
        case .cosmos(let testnet):
            return .tron(testnet: testnet) // TODO
        }
    }
}
