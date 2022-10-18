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
        let fee = BitcoinFee(
            minimalSatoshiPerByte: 10,
            normalSatoshiPerByte: 10,
            prioritySatoshiPerByte: 10
        )
        
        return .justWithError(output: fee)
    }
    
    func send(transaction: String) -> AnyPublisher<String, Error> {
        let target = RavencoinTarget(isTestnet: isTestnet, target: .send(tx: transaction))
        
        return provider.requestPublisher(target)
            .filterSuccessfulStatusCodes()
            .eraseError()
            .print("send(transaction)")
            .map { _ in transaction }
            .eraseToAnyPublisher()
    }
    
    func push(transaction: String) -> AnyPublisher<String, Error> {
        Fail(error: BlockchainSdkError.notImplemented).eraseToAnyPublisher()
    }
    
    func getSignatureCount(address: String) -> AnyPublisher<Int, Error> {
        Fail(error: BlockchainSdkError.notImplemented).eraseToAnyPublisher()
    }
}
