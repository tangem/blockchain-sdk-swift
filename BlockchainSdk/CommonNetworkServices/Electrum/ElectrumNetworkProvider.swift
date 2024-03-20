//
//  ElectrumNetworkProvider.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 11.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine

public class ElectrumNetworkProvider: MultiNetworkProvider {
    let providers: [ElectrumWebSocketManager]
    var currentProviderIndex: Int = 0
    
    private let decimalValue: Decimal
    
    init(providers: [ElectrumWebSocketManager], decimalValue: Decimal) {
        self.providers = providers
        self.decimalValue = decimalValue
    }

    func getAddressInfo(address: String) -> AnyPublisher<ElectrumAddressInfo, Error> {
        providerPublisher { provider in
            Future.async {
                async let balance = provider.getBalance(identifier: .address(address))
                async let unspents = provider.getUnspents(identifier: .address(address))
                
                return try await ElectrumAddressInfo(
                    balance: Decimal(balance.confirmed),
                    outputs: unspents.map { unspent in
                        ElectrumUTXO(
                            position: unspent.txPos,
                            hash: unspent.txHash,
                            value: unspent.value,
                            height: unspent.height
                        )
                    }
                )
            }
            .eraseToAnyPublisher()
        }
    }
    
    func estimateFee() -> AnyPublisher<Decimal, Error> {
        providerPublisher { provider in
            Future.async {
                let fee = try await provider.estimateFee(block: 10)
                return Decimal(fee)
            }
            .eraseToAnyPublisher()
        }
    }
}
