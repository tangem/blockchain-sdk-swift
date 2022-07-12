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
    
    init(network: TronNetwork, tronGridApiKey: String) {
        self.network = network
        self.tronGridApiKey = tronGridApiKey
    }

    func getAccount(for address: String) -> AnyPublisher<TronGetAccountResponse, Error> {
        requestPublisher(for: TronTarget(.getAccount(address: address, network: network), tronGridApiKey: tronGridApiKey))
    }
    
    func getAccountResource(for address: String) -> AnyPublisher<TronGetAccountResourceResponse, Error> {
        requestPublisher(for: TronTarget(.getAccountResource(address: address, network: network), tronGridApiKey: tronGridApiKey))
    }
    
    func getNowBlock() -> AnyPublisher<TronBlock, Error> {
        requestPublisher(for: TronTarget(.getNowBlock(network: network), tronGridApiKey: tronGridApiKey))
    }
    
    func broadcastHex(_ data: Data) -> AnyPublisher<TronBroadcastResponse, Error> {
        requestPublisher(for: TronTarget(.broadcastHex(data: data, network: network), tronGridApiKey: tronGridApiKey))
    }
    
    func tokenBalance(address: String, contractAddress: String) -> AnyPublisher<TronTriggerSmartContractResponse, Error> {
        requestPublisher(for: TronTarget(.tokenBalance(address: address, contractAddress: contractAddress, network: network), tronGridApiKey: tronGridApiKey))
    }
    
    func tokenTransactionHistory(contractAddress: String) -> AnyPublisher<TronTokenHistoryResponse, Error> {
        requestPublisher(for: TronTarget(.tokenTransactionHistory(contractAddress: contractAddress, limit: 50, network: network), tronGridApiKey: tronGridApiKey))
    }
    
    func transactionInfo(id: String) -> AnyPublisher<TronTransactionInfoResponse, Error> {
        requestPublisher(for: TronTarget(.getTransactionInfoById(transactionID: id, network: network), tronGridApiKey: tronGridApiKey))
    }
    
    private func requestPublisher<T: Codable>(for target: TronTarget) -> AnyPublisher<T, Error> {
        return provider.requestPublisher(target)
            .filterSuccessfulStatusAndRedirectCodes()
            .map(T.self)
            .mapError { moyaError in
                if case .objectMapping = moyaError {
                    return WalletError.failedToParseNetworkResponse
                }
                return moyaError
            }
            .eraseToAnyPublisher()
    }
}
