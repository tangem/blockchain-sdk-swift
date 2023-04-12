//
//  TronNetwork.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 24.03.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

enum TronNetwork {
    case nowNodes(apiKey: String)
    case getBlock(apiKey: String)
    case tronGrid(apiKey: String?)
    case nile
    
    var url: URL {
        switch self {
        case .nowNodes:
            return URL(string: "https://trx.nownodes.io")!
        case .getBlock(let apiKey):
            return URL(string: "https://trx.getblock.io/mainnet/\(apiKey)")!
        case .tronGrid:
            return URL(string: "https://api.trongrid.io")!
        case .nile:
            return URL(string: "https://nile.trongrid.io")!
        }
    }
    
    var apiKeyHeaderValue: String? {
        switch self {
        case .nowNodes(let apiKey):
            return apiKey
        case .tronGrid(let apiKey):
            return apiKey
        default:
            return nil
        }
    }
    
    var apiKeyHeaderName: String? {
        switch self {
        case .nowNodes:
            return Constants.nowNodesApiKeyHeaderName
        case .tronGrid:
            return "TRON-PRO-API-KEY"
        default:
            return nil
        }
    }
}
