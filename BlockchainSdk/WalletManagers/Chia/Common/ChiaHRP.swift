//
//  ChiaHRP.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 31.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

/// Prefix address Chia blockchain
enum ChiaHRP: String {
    case txch, xch
    
    init(isTestnet: Bool) {
        self = isTestnet ? .txch : .xch
    }
}
