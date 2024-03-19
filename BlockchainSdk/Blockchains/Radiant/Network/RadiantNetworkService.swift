//
//  RadiantNetworkService.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 05.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class RadiantNetworkService {
    let electrumProvider: ElectrumNetworkProvider
    
    init(electrumProvider: ElectrumNetworkProvider) {
        self.electrumProvider = electrumProvider
    }
}

extension RadiantNetworkService: HostProvider {
    var host: String {
        electrumProvider.host
    }
}

extension RadiantNetworkService {
    func getInfo(scripthash: String) -> AnyPublisher<ElectrumAddressInfo, Error> {
        electrumProvider
            .getAddressInfo(identifier: .scripthash(scripthash))
    }
    
    func estimatedFee() -> AnyPublisher<Decimal, Error> {
        electrumProvider
            .estimateFee()
    }
}
