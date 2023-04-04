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

class RavencoinMultiNetworkProvider: MultiNetworkProvider {
    var currentProviderIndex: Int = 0
    let providers: [RavencoinNetworkProvider]
    
    init(configuration: NetworkProviderConfiguration) {
        let hosts = ["https://ravencoin.network/api", "https://api.ravencoin.org/api/"]

        providers = hosts.map { host in
            RavencoinNetworkProvider(
                host: host,
                provider: NetworkProvider<RavencoinTarget>(configuration: configuration)
            )
        }
    }
}

class RavencoinNetworkProvider: HostProvider {
    let host: String
    let provider: NetworkProvider<RavencoinTarget>
    
    init(host: String, provider: NetworkProvider<RavencoinTarget>) {
        self.host = host
        self.provider = provider
    }

    func getInfo(address: String) -> AnyPublisher<RavencoinWalletInfo, Error> {
        provider
            .requestPublisher(.init(host: host, target: .wallet(address: address)))
            .map(RavencoinWalletInfo.self)
            .eraseError()
    }
    
    func getUTXO(address: String) -> AnyPublisher<[RavencoinWalletUTXO], Error> {
        provider
            .requestPublisher(.init(host: host, target: .utxo(address: address)))
            .map([RavencoinWalletUTXO].self)
            .eraseError()
    }
    
    func getTxInfo(transactionId: String) -> AnyPublisher<RavencoinTransactionInfo, Error> {
        provider
            .requestPublisher(.init(host: host, target: .transaction(id: transactionId)))
            .map(RavencoinTransactionInfo.self)
            .eraseError()
    }
    
    func getUTXO(raw: RavencoinRawTransactionRequestModel) -> AnyPublisher<Void, Error> {
        provider
            .requestPublisher(.init(host: host, target: .sendTransaction(raw: raw)))
            .map { response in
                print(String(bytes: response.data, encoding: .utf8)!)
                return Void()
            }
            .eraseToAnyPublisher()
            .eraseError()
    }
}
