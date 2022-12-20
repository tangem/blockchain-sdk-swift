//
//  BlockBookService.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 20.12.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

enum BlockBookService {
    case nownodes
    case getblock

    func path(for request: BlockBookTarget.Request) -> String {
        switch request {
        case .fees:
            switch self {
            case .nownodes:
                return ""
            case .getblock:
                return "/mainnet"
            }
        default:
            switch self {
            case .nownodes:
                return "/api/v2"
            case .getblock:
                return "/mainnet/blockbook/api/v2"
            }
        }
    }

    func domain(for request: BlockBookTarget.Request, blockchain: Blockchain) -> String {
        let currencySymbolPrefix = blockchain.currencySymbol.lowercased()
        
        switch request {
        case .fees:
            switch self {
            case .nownodes:
                return "https://\(currencySymbolPrefix).nownodes.io"
            case .getblock:
                return "https://\(currencySymbolPrefix).getblock.io"
            }
        default:
            switch self {
            case .nownodes:
                let testnetSuffix = blockchain.isTestnet ? "-testnet" : ""
                return "https://\(currencySymbolPrefix)book\(testnetSuffix).nownodes.io"
            case .getblock:
                return "https://\(currencySymbolPrefix).getblock.io"
            }
        }
    }
}
