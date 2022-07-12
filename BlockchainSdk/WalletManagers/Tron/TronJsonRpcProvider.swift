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
        network.url.hostOrUnknown
    }

    private let network: TronNetwork
    private let tronGridApiKey: String
    private let provider = MoyaProvider<TronTarget>(plugins: [NetworkLoggerPlugin()])
    
    private var currentApiKey: String?
    
    init(network: TronNetwork, tronGridApiKey: String) {
        self.network = network
        self.tronGridApiKey = tronGridApiKey
    }

    func getAccount(for address: String) -> AnyPublisher<TronGetAccountResponse, Error> {
        requestPublisher(for: .getAccount(address: address, network: network))
    }
    
    func getAccountResource(for address: String) -> AnyPublisher<TronGetAccountResourceResponse, Error> {
        requestPublisher(for: .getAccountResource(address: address, network: network))
    }
    
    func getNowBlock() -> AnyPublisher<TronBlock, Error> {
        requestPublisher(for: .getNowBlock(network: network))
    }
    
    func broadcastHex(_ data: Data) -> AnyPublisher<TronBroadcastResponse, Error> {
        requestPublisher(for: .broadcastHex(data: data, network: network))
    }
    
    func tokenBalance(address: String, contractAddress: String) -> AnyPublisher<TronTriggerSmartContractResponse, Error> {
        requestPublisher(for: .tokenBalance(address: address, contractAddress: contractAddress, network: network))
    }
    
    func tokenTransactionHistory(contractAddress: String) -> AnyPublisher<TronTokenHistoryResponse, Error> {
        requestPublisher(for: .tokenTransactionHistory(contractAddress: contractAddress, limit: 50, network: network))
    }
    
    func transactionInfo(id: String) -> AnyPublisher<TronTransactionInfoResponse, Error> {
        requestPublisher(for: .getTransactionInfoById(transactionID: id, network: network))
    }
    
    private func requestPublisher<T: Codable>(for target: TronTarget.TronTargetType, apiKey: String? = nil) -> AnyPublisher<T, Error> {
        return provider.requestPublisher(TronTarget(target, tronGridApiKey: currentApiKey))
            .filterSuccessfulStatusAndRedirectCodes()
            .map(T.self)
            .eraseError()
            .tryCatch { [weak self] error -> AnyPublisher<T, Error> in
                guard let self = self else {
                    throw error
                }
                
                if self.needRetryWithKey(error) && apiKey == nil {
                    self.currentApiKey = self.tronGridApiKey
                    return self.requestPublisher(for: target, apiKey: self.currentApiKey)
                } else {
                    return Fail(error: error).eraseToAnyPublisher()
                }
            }
            .mapError { error in
                if let moyaError = error as? MoyaError,
                   case .objectMapping = moyaError
                {
                    return WalletError.failedToParseNetworkResponse
                }
                return error
            }
            .eraseToAnyPublisher()
    }
    
    private func needRetryWithKey(_ error: Error) -> Bool {
        if case let MoyaError.statusCode(response) = error {
            // TronGrid returns 503 when service is unavailable, but keep the rest just in case
            switch response.statusCode {
            case 402, 429, 430, 434, 503:
                return true
            default:
                return false
            }
        } else {
            return false
        }
    }
}
