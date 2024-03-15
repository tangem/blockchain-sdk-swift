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
    let electrumProvider: RadiantNetworkProvider
    
    init(electrumProvider: RadiantNetworkProvider) {
        self.electrumProvider = electrumProvider
    }
}

extension RadiantNetworkService: HostProvider {
    var host: String {
        electrumProvider.host
    }
}

extension RadiantNetworkService {
    func getInfo(address: String) -> AnyPublisher<Decimal, Error> {
        electrumProvider
            .getBalance(address: address)
    }
    
    func getUnspents(address: String) -> AnyPublisher<[BitcoinUnspentOutput], Error> {
        electrumProvider
            .getUnspents(address: address)
            .map { utxos in
                return []
            }
            .eraseToAnyPublisher()
    }
}
