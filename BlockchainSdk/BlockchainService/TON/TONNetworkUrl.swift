//
//  TONNetwork.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 12.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

enum TONNetworkUrl {
    case mainnet
    case testnet
    
    var host: String {
        switch self {
        case .mainnet:
            return "https://toncenter.com/api/v2/"
        case .testnet:
            return "https://testnet.toncenter.com/api/v2/"
        }
    }
    
    var url: URL {
        return URL(string: self.host)!
    }
    
    init(_ testnet: Bool) {
        self = testnet ? .testnet : .mainnet
    }
}
