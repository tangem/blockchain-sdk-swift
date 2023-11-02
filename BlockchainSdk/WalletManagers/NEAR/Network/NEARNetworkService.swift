//
//  NEARNetworkService.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 13.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class NEARNetworkService: MultiNetworkProvider {
    let providers: [NEARNetworkProvider]
    var currentProviderIndex: Int = 0

    private let blockchain: Blockchain

    init(
        blockchain: Blockchain,
        providers: [NEARNetworkProvider]
    ) {
        self.blockchain = blockchain
        self.providers = providers
    }
}
