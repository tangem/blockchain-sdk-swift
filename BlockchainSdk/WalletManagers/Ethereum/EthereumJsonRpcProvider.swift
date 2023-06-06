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
    let url: URL
    
    var host: String {
        url.hostOrUnknown
    }
    
    var exceptionLogger: ExternalExceptionHandler?
    
    private let provider: NetworkProvider<EthereumTarget>

    init(url: URL, configuration: NetworkProviderConfiguration) {
        self.url = url
        provider = NetworkProvider<EthereumTarget>(configuration: configuration)
    }
    
    func read(contractAddress: String, encodedData: String) -> AnyPublisher<EthereumResponse, Error> {
        return requestPublisher(for: .read(contractAddress: contractAddress, encodedData: encodedData))
    }
    
    func getBalance(for address: String) -> AnyPublisher<EthereumResponse, Error> {
        requestPublisher(for: .balance(address: address))
    }
    
    func getTokenBalance(for address: String, contractAddress: String) -> AnyPublisher<EthereumResponse, Error> {
        requestPublisher(for: .tokenBalance(address: address, contractAddress: contractAddress))
    }
    
    func getTxCount(for address: String) -> AnyPublisher<EthereumResponse, Error> {
        requestPublisher(for: .transactions(address: address))
    }
    
    func getPendingTxCount(for address: String) -> AnyPublisher<EthereumResponse, Error> {
        requestPublisher(for: .pending(address: address))
    }
    
    func send(transaction: String) -> AnyPublisher<EthereumResponse, Error> {
        requestPublisher(for: .send(transaction: transaction))
    }
    
    func getGasLimit(to: String, from: String, value: String?, data: String?) -> AnyPublisher<EthereumResponse, Error> {
        requestPublisher(for: .gasLimit(to: to, from: from, value: value, data: data))
    }
    
    func getGasPrice() -> AnyPublisher<EthereumResponse, Error> {
        requestPublisher(for: .gasPrice)
    }

    func getAllowance(from: String, to: String, contractAddress: String) -> AnyPublisher<EthereumResponse, Error> {
        requestPublisher(for: .getAllowance(from: from, to: to, contractAddress: contractAddress))
    }
    
    private func requestPublisher(for targetType: EthereumTarget.EthereumTargetType) -> AnyPublisher<EthereumResponse, Error> {
        provider.requestPublisher(
            EthereumTarget(
                targetType: targetType,
                baseURL: url
            )
        )
        .filterSuccessfulStatusAndRedirectCodes()
        .map(EthereumResponse.self)
        .mapError { $0 }
        .eraseToAnyPublisher()
    }
}
