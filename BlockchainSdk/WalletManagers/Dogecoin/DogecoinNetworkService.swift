//
//  DogecoinNetworkService.swift
//  BlockchainSdk
//
//  Created by Andrew Son on 25/05/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class DogecoinNetworkService: BitcoinNetworkService {
    override func getFee() -> AnyPublisher<BitcoinFee, Error> {
        providerPublisher { provider in
            provider.getFee()
                .retry(2)
                .eraseToAnyPublisher()
        }
    }
}
