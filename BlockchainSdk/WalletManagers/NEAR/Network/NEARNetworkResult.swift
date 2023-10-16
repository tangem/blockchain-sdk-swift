//
//  NEARNetworkResult.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 13.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

enum NEARNetworkResult {
    struct AccountInfo: Decodable {
        let amount: String
        let locked: String
        let codeHash: String
        let storageUsage: UInt
        let storagePaidAt: UInt
        let blockHeight: UInt
        let blockHash: String
    }
}
