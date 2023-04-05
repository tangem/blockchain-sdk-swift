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

/// https://github.com/RavenProject/Ravencoin/blob/master/doc/REST-interface.md
/// https://github.com/RavenDevKit/insight-api
class RavencoinNetworkProvider: HostProvider {
    let host: String
    let provider: NetworkProvider<RavencoinTarget>
    
    init(host: String, provider: NetworkProvider<RavencoinTarget>) {
        self.host = host
        self.provider = provider
    }
    
    func getWalletInfo(address: String) -> AnyPublisher<RavencoinWalletInfo, Error> {
        provider
            .requestPublisher(.init(host: host, target: .wallet(address: address)))
            .map(RavencoinWalletInfo.self)
            .eraseError()
    }
    
    func getTransactions(address: String) -> AnyPublisher<[RavencoinTransactionInfo], Error> {
        provider
            .requestPublisher(.init(host: host, target: .transactions(address: address)))
            .map([RavencoinTransactionInfo].self)
            .eraseError()
    }
    
    func getUTXO(address: String) -> AnyPublisher<[RavencoinWalletUTXO], Error> {
        provider
            .requestPublisher(.init(host: host, target: .utxo(address: address)))
            .map([RavencoinWalletUTXO].self)
            .eraseError()
    }
    
    func getFeeRateByBite(blocks: Int) -> AnyPublisher<Decimal, Error> {
        provider
            .requestPublisher(.init(host: host, target: .fees(request: .init(nbBlocks: blocks))))
            .mapJSON(failsOnEmptyData: true)
            .compactMap { $0 as? [String: Any] }
            .compactMap { $0["\(blocks)"] as? Decimal } // Get rate per kilobyte
            .map { $0 / 1024 }
            .eraseToAnyPublisher()
            .eraseError()
    }
    
    func getTxInfo(transactionId: String) -> AnyPublisher<RavencoinTransactionInfo, Error> {
        provider
            .requestPublisher(.init(host: host, target: .transaction(id: transactionId)))
            .map(RavencoinTransactionInfo.self)
            .eraseError()
    }
    
    func send(transaction: RavencoinRawTransaction.Request) -> AnyPublisher<RavencoinRawTransaction.Response, Error> {
        provider
            .requestPublisher(.init(host: host, target: .send(transaction: transaction)))
            .map(RavencoinRawTransaction.Response.self)
            .eraseToAnyPublisher()
            .eraseError()
    }
}
