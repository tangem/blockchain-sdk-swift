//
//  ElectrumNetworkProvider.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 11.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine

class ElectrumNetworkProvider: MultiNetworkProvider {
    let providers: [ElectrumWebSocketProvider]
    var currentProviderIndex: Int = 0

    init(providers: [ElectrumWebSocketProvider]) {
        self.providers = providers
    }

    public func getAddressInfo(address: String) -> AnyPublisher<ElectrumAddressInfo, Error> {
        providerPublisher { provider in
            Future.async {
                let unspents = try await provider.getUnspents(identifier: .address(address))
                
                return ElectrumAddressInfo(
                    outputs: unspents.map { unspent in
                        ElectrumUTXO(
                            position: unspent.txPos,
                            hash: unspent.txHash,
                            value: unspent.value,
                            outpoint: unspent.outpointHash,
                            height: unspent.height
                        )
                    }
                )
            }
            .eraseToAnyPublisher()
        }
    }
    
    public func estimateFee() -> AnyPublisher<Decimal, Error> {
        providerPublisher { provider in
            Future.async {
                let fee = try await provider.estimateFee(block: Constants.estimateFeeBlocks)
                return Decimal(fee)
            }
            .eraseToAnyPublisher()
        }
    }
}

extension ElectrumNetworkProvider {
    private enum Constants {
        // From documentation
        static let estimateFeeBlocks: Int = 6
    }
}
