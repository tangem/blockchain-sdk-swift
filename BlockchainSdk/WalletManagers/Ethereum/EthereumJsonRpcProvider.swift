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
    
    var host: String {
        network.url.hostOrUnknown
    }
    
    private let provider: MoyaProvider<EthereumTarget> = .init(
        plugins: [NetworkLoggerPlugin()]
    )
    private let network: EthereumNetwork
    
    init(network: EthereumNetwork) {
        self.network = network
    }
    
    func getBalance(for address: String) -> AnyPublisher<EthereumResponse, Error> {
        requestPublisher(for: .balance(address: address, network: network))
    }
    
    func getTokenBalance(for address: String, contractAddress: String) -> AnyPublisher<EthereumResponse, Error> {
        requestPublisher(for: .tokenBalance(address: address, contractAddress: contractAddress, network: network))
    }
    
    func getTxCount(for address: String) -> AnyPublisher<EthereumResponse, Error> {
        requestPublisher(for: .transactions(address: address, network: network))
    }
    
    func getPendingTxCount(for address: String) -> AnyPublisher<EthereumResponse, Error> {
        requestPublisher(for: .pending(address: address, network: network))
    }
    
    func send(transaction: String) -> AnyPublisher<EthereumResponse, Error> {
        requestPublisher(for: .send(transaction: transaction, network: network))
    }
    
    func getGasLimit(to: String, from: String, data: String?) -> AnyPublisher<EthereumResponse, Error> {
        requestPublisher(for: .gasLimit(to: to, from: from, data: data, network: network))
    }
    
    func getGasPrice() -> AnyPublisher<EthereumResponse, Error> {
        requestPublisher(for: .gasPrice(network: network))
    }
    
    private func requestPublisher(for target: EthereumTarget) -> AnyPublisher<EthereumResponse, Error> {
        provider.requestPublisher(target)
            .filterSuccessfulStatusAndRedirectCodes()
            .map(EthereumResponse.self)
            .mapError { $0 }
            .eraseToAnyPublisher()
    }
}
