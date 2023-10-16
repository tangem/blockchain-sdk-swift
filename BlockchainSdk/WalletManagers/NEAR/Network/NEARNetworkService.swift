//
//  NEARNetworkService.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 13.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BigInt

// TODO: Andrey Fedorov - Do we need blockchain info here?
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

    func getInfo(accountId: String) -> AnyPublisher<NEARAccountInfo, Error> {
        // TODO: Andrey Fedorov - Add actual implementation
        let value: Decimal = 10.0
        let info = NEARAccountInfo(
            accountId: accountId,
            amount: Amount(with: blockchain, value: value)
        )
        return .justWithError(output: info)
    }
}
