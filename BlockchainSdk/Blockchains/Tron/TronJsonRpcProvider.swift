//
//  TronJsonRpcProvider.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 24.03.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Moya

class TronJsonRpcProvider: HostProvider {
    var host: String {
        node.url.absoluteString + (node.headers?.headerValue == nil ? "" : " (API KEY)")
    }

    private let node: NodeInfo
    private let provider: NetworkProvider<TronTarget>
    
    init(node: NodeInfo, configuration: NetworkProviderConfiguration) {
        self.node = node
        provider = NetworkProvider<TronTarget>(configuration: configuration)
    }
    
    func getChainParameters() -> AnyPublisher<TronGetChainParametersResponse, Error> {
        requestPublisher(for: .getChainParameters)
    }

    func getAccount(for address: String) -> AnyPublisher<TronGetAccountResponse, Error> {
        requestPublisher(for: .getAccount(address: address))
    }
    
    func getAccountResource(for address: String) -> AnyPublisher<TronGetAccountResourceResponse, Error> {
        requestPublisher(for: .getAccountResource(address: address), checkForEmpty: true)
    }
    
    func getNowBlock() -> AnyPublisher<TronBlock, Error> {
        requestPublisher(for: .getNowBlock)
    }
    
    func broadcastHex(_ data: Data) -> AnyPublisher<TronBroadcastResponse, Error> {
        requestPublisher(for: .broadcastHex(data: data))
    }
    
    func tokenBalance(address: String, contractAddress: String) -> AnyPublisher<TronTriggerSmartContractResponse, Error> {
        requestPublisher(for: .tokenBalance(address: address, contractAddress: contractAddress))
    }
    
    func contractEnergyUsage(sourceAddress: String, contractAddress: String, parameter: String) -> AnyPublisher<TronContractEnergyUsageResponse, Error> {
        requestPublisher(for: .contractEnergyUsage(sourceAddress: sourceAddress, contractAddress: contractAddress, parameter: parameter))
    }
    
    func transactionInfo(id: String) -> AnyPublisher<TronTransactionInfoResponse, Error> {
        requestPublisher(for: .getTransactionInfoById(transactionID: id))
    }
    
    private func requestPublisher<T: Codable>(for target: TronTarget.TronTargetType, checkForEmpty: Bool = false) -> AnyPublisher<T, Error> {
        let requestPublisher = provider.requestPublisher(TronTarget(node: node, target))
            .filterSuccessfulStatusAndRedirectCodes()
            .share()
            .eraseToAnyPublisher()
        
        let isEmptyResponsePublisher = requestPublisher
            .map { response in
                guard checkForEmpty, let value = String(data: response.data, encoding: .utf8) else {
                    return false
                }
                return value.trimmingCharacters(in: .whitespacesAndNewlines) == "{}"
            }
            .mapToResult()
            .eraseToAnyPublisher()
        
        return requestPublisher
            .map(T.self)
            .mapError { moyaError -> Error in
                if case .objectMapping = moyaError {
                    return WalletError.failedToParseNetworkResponse
                }
                return moyaError
            }
            .mapToResult()
            .zip(isEmptyResponsePublisher)
            .tryMap { value, isEmptyResponse in
                switch isEmptyResponse {
                case .success(true):
                    throw ValidationError.accountNotActivated
                case let .failure(error):
                    throw error
                default:
                    break
                }
                
                switch value {
                case let .success(value):
                    return value
                case let .failure(error):
                    throw error
                }
            }
            .eraseToAnyPublisher()
    }
}
