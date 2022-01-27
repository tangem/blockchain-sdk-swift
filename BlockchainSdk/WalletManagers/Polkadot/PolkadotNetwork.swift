//
//  PolkadotNetwork.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 27.01.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

enum PolkadotNetwork {
    case westend
    
    var url: URL {
        switch self {
        case .westend:
            return URL(string: "https://westend-rpc.polkadot.io")!
        }
    }
}
