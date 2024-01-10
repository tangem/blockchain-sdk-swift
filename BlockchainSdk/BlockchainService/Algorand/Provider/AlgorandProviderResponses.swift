//
//  AlgorandResponses.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 10.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct AlgorandErrorResponse: Error {
    let message: String
}

struct AlgorandResponse: Decodable {}
