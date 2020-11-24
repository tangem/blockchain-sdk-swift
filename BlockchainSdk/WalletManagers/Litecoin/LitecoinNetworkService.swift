//
//  LitecoinNetworkService.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 31.01.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class LitecoinNetworkService: BitcoinNetworkService {
    convenience init(isTestNet:Bool) {
        var providers = [BitcoinNetworkApi:BitcoinNetworkProvider]()
        providers[.blockcypher] = BlockcypherProvider(coin: .ltc, chain: .main)
        self.init(providers: providers, isTestNet: isTestNet)
    }
}
