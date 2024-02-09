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

    let helperNode: NetworkNode
    let mirrorNode: NetworkNode
}
