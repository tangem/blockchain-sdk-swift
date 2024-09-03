//
//  FilecoinTxInfo.swift
//  BlockchainSdk
//
//  Created by Aleksei Muraveinik on 27.08.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct FilecoinTxInfo {
    let sourceAddress: String
    let destinationAddress: String
    let amount: UInt64
    let nonce: UInt64
}
