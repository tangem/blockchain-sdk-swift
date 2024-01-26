//
//  HederaNetworkService.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 25.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

final class HederaNetworkService: MultiNetworkProvider {
    var currentProviderIndex = 0

    var providers: [HederaNetworkProvider] {
        // TODO: Andrey Fedorov - Add actual implementation (IOS-4556)
        return []
    }
}
