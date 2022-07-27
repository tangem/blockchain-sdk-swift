//
//  EthereumJsonRpcProvider.swift
//  BlockchainSdk
//
//  Created by Andrew Son on 01/05/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BigInt
import Moya

class EthereumJsonRpcProvider: HostProvider {
    let host: String
    
    private let provider: NetworkProvider<EthereumTarget>
    private let url: URL
    
    init(url: URL, configuration: NetworkProviderConfiguration) {
        self.url = url
        self.host = url.hostOrUnknown
        provider = NetworkProvider<EthereumTarget>(configuration: configuration)
    }
    
    func getBalance(for address: String) -> AnyPublisher<EthereumResponse, Error> {
        requestPublisher(for: .balance(address: address, url: url))
    }
    
    func getTokenBalance(for address: String, contractAddress: String) -> AnyPublisher<EthereumResponse, Error> {
        requestPublisher(for: .tokenBalance(address: address, contractAddress: contractAddress, url: url))
    }
    
    func getTxCount(for address: String) -> AnyPublisher<EthereumResponse, Error> {
        requestPublisher(for: .transactions(address: address, url: url))
    }
    
    func getPendingTxCount(for address: String) -> AnyPublisher<EthereumResponse, Error> {
        requestPublisher(for: .pending(address: address, url: url))
    }
    
    func send(transaction: String) -> AnyPublisher<EthereumResponse, Error> {
        requestPublisher(for: .send(transaction: transaction, url: url))
    }
    
    func getGasLimit(to: String, from: String, data: String?) -> AnyPublisher<EthereumResponse, Error> {
        requestPublisher(for: .gasLimit(to: to, from: from, data: data, url: url))
    }
    
    func getGasPrice() -> AnyPublisher<EthereumResponse, Error> {
        requestPublisher(for: .gasPrice(url: url))
    }
    
    private func requestPublisher(for target: EthereumTarget) -> AnyPublisher<EthereumResponse, Error> {
        provider.requestPublisher(target)
            .filterSuccessfulStatusAndRedirectCodes()
            .map(EthereumResponse.self)
            .mapError { $0 }
            .eraseToAnyPublisher()
    }
}
