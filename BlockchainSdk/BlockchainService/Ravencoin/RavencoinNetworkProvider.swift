//
//  RavencoinNetworkProvider.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 16.10.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine

class RavencoinNetworkProvider {
    private let isTestnet: Bool
    private let provider = NetworkProvider<RavencoinTarget>()
    
    init(isTestnet: Bool) {
        self.isTestnet = isTestnet
    }
}

extension RavencoinNetworkProvider: BitcoinNetworkProvider {
    var supportsTransactionPush: Bool { false }
    var host: String {
        RavencoinTarget(isTestnet: isTestnet, target: .addressInfo("")).baseURL.absoluteString
    }
    
    func getInfo(address: String) -> AnyPublisher<BitcoinResponse, Error> {
        let target = RavencoinTarget(isTestnet: isTestnet, target: .addressInfo(address))
        return provider.requestPublisher(target)
            .filterSuccessfulStatusCodes()
            .map(RavencoinAddressResponse.self)
            .eraseError()
            .map { ravencoinResponse -> BitcoinResponse in
                BitcoinResponse(
                    balance: ravencoinResponse.balance,
                    hasUnconfirmed: ravencoinResponse.unconfirmedTxApperances > 0,
                    pendingTxRefs: [],
                    unspentOutputs: []
                )
            }
            .eraseToAnyPublisher()
    }
    
    func getFee() -> AnyPublisher<BitcoinFee, Error> {
        .emptyFail
    }
    
    func send(transaction: String) -> AnyPublisher<String, Error> {
        .emptyFail
    }
    
    func push(transaction: String) -> AnyPublisher<String, Error> {
        .emptyFail
    }
    
    func getSignatureCount(address: String) -> AnyPublisher<Int, Error> {
        .emptyFail
    }
}
