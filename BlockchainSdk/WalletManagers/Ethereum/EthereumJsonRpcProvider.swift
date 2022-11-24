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
    
    private let provider: NetworkProvider<EvmRawTarget>
    private let url: URL
    private let targetBuilder: EvmTargetBuilder
    
    init(url: URL, targetBuilder: EvmTargetBuilder, configuration: NetworkProviderConfiguration) {
        self.url = url
        self.host = url.hostOrUnknown
        self.targetBuilder = targetBuilder
        provider = NetworkProvider<EvmRawTarget>(configuration: configuration)
    }
    
    func getBalance(for address: String) -> AnyPublisher<EthereumResponse, Error> {
        requestPublisher(for: targetBuilder.balance(address: address))
    }
    
    func getTokenBalance(for address: String, contractAddress: String) -> AnyPublisher<EthereumResponse, Error> {
        requestPublisher(for: targetBuilder.tokenBalance(address: address, contractAddress: contractAddress))
    }
    
    func getTxCount(for address: String) -> AnyPublisher<EthereumResponse, Error> {
        requestPublisher(for: targetBuilder.transactions(address: address))
    }
    
    func getPendingTxCount(for address: String) -> AnyPublisher<EthereumResponse, Error> {
        requestPublisher(for: targetBuilder.pending(address: address))
    }
    
    func send(transaction: String) -> AnyPublisher<EthereumResponse, Error> {
        requestPublisher(for: targetBuilder.send(transaction: transaction))
    }
    
    func getGasLimit(to: String, from: String, value: String?, data: String?) -> AnyPublisher<EthereumResponse, Error> {
        requestPublisher(for: targetBuilder.gasLimit(to: to, from: from, value: value, data: data))
    }
    
    func getGasPrice() -> AnyPublisher<EthereumResponse, Error> {
        requestPublisher(for: targetBuilder.gasPrice())
    }
    
    private func requestPublisher(for target: EvmRawTarget) -> AnyPublisher<EthereumResponse, Error> {
        provider.requestPublisher(target)
            .filterSuccessfulStatusAndRedirectCodes()
            .map(EthereumResponse.self)
            .mapError { $0 }
            .eraseToAnyPublisher()
    }
}
