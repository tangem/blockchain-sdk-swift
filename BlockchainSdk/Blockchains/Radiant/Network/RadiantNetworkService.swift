//
//  RadiantNetworkService.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 05.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class RadiantNetworkService: BitcoinNetworkService {
    override func getInfo(addresses: [String]) -> AnyPublisher<[BitcoinResponse], Error> {
        super.getInfo(address: addresses[0].removeBchPrefix())
            .map { [$0] }
            .eraseToAnyPublisher()
    }
    override func getInfo(address: String) -> AnyPublisher<BitcoinResponse, Error> {
        super.getInfo(address: address.removeBchPrefix())
    }
    
    override func getSignatureCount(address: String) -> AnyPublisher<Int, Error> {
        super.getSignatureCount(address: address.removeBchPrefix()) //TODO: check it!
    }
}
