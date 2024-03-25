//
//  NexaNetworkProvider.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 19.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

// TODO: Will change on the real
class ElectrumNetworkProvider: HostProvider {
    var host: String = UUID().uuidString
}

class NexaNetworkProvider: MultiNetworkProvider {
    var currentProviderIndex: Int = 1
    let providers: [ElectrumNetworkProvider]
    
    init(providers: [ElectrumNetworkProvider]) {
        self.providers = providers
    }
}
