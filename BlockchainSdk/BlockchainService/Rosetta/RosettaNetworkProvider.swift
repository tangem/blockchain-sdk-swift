//
//  RosettaNetworkProvider.swift
//  BlockchainSdk
//
//  Created by Andrew Son on 10/03/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class RosettaNetworkProvider: CardanoNetworkProvider {
    func getInfo(address: String) -> AnyPublisher<CardanoAddressResponse, Error> {
        .anyFail(error: "Rosetta network is unreachable")
    }
    
    func send(transaction: Data) -> AnyPublisher<String, Error> {
        .anyFail(error: "Rosetta network is unreachable")
    }
}
