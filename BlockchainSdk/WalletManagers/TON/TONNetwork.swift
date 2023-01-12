//
//  TONNetwork.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 12.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

enum TONNetwork {
    case mainnet
    case testnet
    
    var url: URL {
        switch self {
        case .mainnet:
            return URL(string: "https://tonapi.io/")!
        case .testnet:
            return URL(string: "https://testnet.tonapi.io/")!
        }
    }
}
