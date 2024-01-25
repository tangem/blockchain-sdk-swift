//
//  AptosBuildParams.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 25.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct AptosBuildParams {
    let chainId: UInt32
    let sequenceNumber: Int64
    let expirationTimestampSecs: UInt64
}
