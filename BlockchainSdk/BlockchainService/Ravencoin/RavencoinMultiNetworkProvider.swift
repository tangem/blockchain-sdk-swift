//
//  RavencoinMultiNetworkProvider.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 05.04.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

class RavencoinMultiNetworkProvider: MultiNetworkProvider {
    var currentProviderIndex: Int = 0
    let providers: [RavencoinNetworkProvider]
    
    init(isTestnet: Bool, configuration: NetworkProviderConfiguration) {
        if isTestnet {
            providers = [RavencoinNetworkProvider(
                host: "https://testnet.ravencoin.org/api/",
                provider: NetworkProvider<RavencoinTarget>(configuration: configuration)
            )]
        } else {
            let hosts = ["https://api.ravencoin.org/api/", "https://ravencoin.network/api"]
            providers = hosts.map { host in
                RavencoinNetworkProvider(
                    host: host,
                    provider: NetworkProvider<RavencoinTarget>(configuration: configuration)
                )
            }
        }
    }
}
