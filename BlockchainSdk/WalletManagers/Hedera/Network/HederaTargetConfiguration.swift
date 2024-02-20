//
//  HederaTargetConfiguration.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 09.02.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

/// Hedera mirror provided by Hedera itself or third-party providers.
struct HederaTargetConfiguration {
    var baseURL: URL
    var apiKeyHeaderName: String?
    var apiKeyHeaderValue: String?
}
