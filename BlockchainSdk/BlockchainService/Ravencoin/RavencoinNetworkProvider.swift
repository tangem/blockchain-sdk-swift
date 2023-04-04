//
//  RavencoinNetworkProvider.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 03.04.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import Combine

/*
curl 'https://ravencoin.network/v1/raven/address/R9evUf3dCSfzdjuRJgvBxAnjA7TPjDYjPo/utxo' \
 -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.1 Safari/605.1.15'
-X 'GET' \
-H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.1 Safari/605.1.15'
{"apiVersion":"1","status":{"code":200,"message":"OK"},"data":{"items":[{"rvnAddress":"R9evUf3dCSfzdjuRJgvBxAnjA7TPjDYjPo","totalReceived":900000000,"totalReceivedDisplayValue":"9","totalSent":0,"totalSentDisplayValue":"0","finalBalance":900000000,"finalBalanceDisplayValue":"9","txCount":1,"blockHash":"00000000000015ca462a0bc9b53a7e5e1fe81ef3e03987096445f26f040497af","blockHeight":2500370}]}}%
*/

struct RavencoinNetworkProvider {
    let provider: NetworkProvider<RavencoinTarget>
    
    init(configuration: NetworkProviderConfiguration) {
        provider = NetworkProvider<RavencoinTarget>(configuration: configuration)
    }

    func getInfo(address: String) -> AnyPublisher<RavencoinWalletInfo, Error> {
        provider
            .requestPublisher(.wallet(address: address))
            .map(RavencoinWalletInfo.self)
            .eraseError()
    }
    
    func getUTXO(address: String) -> AnyPublisher<[RavencoinWalletUTXO], Error> {
        provider
            .requestPublisher(.utxo(address: address))
            .map([RavencoinWalletUTXO].self)
            .eraseError()
    }
    
    func getTxInfo(transactionId: String) -> AnyPublisher<RavencoinTransactionInfo, Error> {
        provider
            .requestPublisher(.transaction(id: transactionId))
            .map(RavencoinTransactionInfo.self)
            .eraseError()
    }
    
    func getUTXO(raw: RavencoinRawTransactionRequestModel) -> AnyPublisher<Void, Error> {
        provider
            .requestPublisher(.sendTransaction(raw: raw))
            .map { _ in Void() }
            .eraseToAnyPublisher()
            .eraseError()
    }
}
