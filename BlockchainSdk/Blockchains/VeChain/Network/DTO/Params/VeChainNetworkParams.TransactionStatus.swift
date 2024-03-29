//
//  VeChainNetworkParams.TransactionStatus.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 20.12.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

extension VeChainNetworkParams {
    struct TransactionStatus {
        let hash: String
        let includePending: Bool
        let rawOutput: Bool
    }
}
