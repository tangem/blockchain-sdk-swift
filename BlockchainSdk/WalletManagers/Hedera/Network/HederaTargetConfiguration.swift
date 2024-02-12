//
//  HederaTargetConfiguration.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 09.02.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct HederaTargetConfiguration {
    struct NetworkNode {
        var baseURL: URL
        var apiKeyHeaderName: String?
        var apiKeyHeaderValue: String?
    }

    /// Handles manual account creation and other tasks; provided by Tangem.
    let helperNode: NetworkNode

    /// Hedera mirror provided by Hedera itself or third-party providers.
    let mirrorNode: NetworkNode
}
