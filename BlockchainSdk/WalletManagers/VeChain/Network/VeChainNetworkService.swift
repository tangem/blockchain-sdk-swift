//
//  VeChainNetworkService.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 18.12.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

// TODO: Andrey Fedorov - Add actual implementation (IOS-5239)
final class VeChainNetworkService: MultiNetworkProvider {
    let providers: [VeChainNetworkProvider]
    var currentProviderIndex: Int

    init(
        providers: [VeChainNetworkProvider]
    ) {
        self.providers = providers
        currentProviderIndex = 0
    }
}
