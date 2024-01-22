//
//  AlgorandResponse+Error.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 12.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

extension AlgorandResponse {
    struct Error: Swift.Error, Decodable {
        let message: String
    }
}
